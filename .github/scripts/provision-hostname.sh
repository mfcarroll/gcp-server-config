#!/bin/bash
# Exit immediately if a command exits with a non-zero status.
set -e

# Construct the hostname from environment variables
HOSTNAME="${APPNAME}.${DOMAIN_NAME}"

# --- Check if Custom Hostname exists ---
echo "Checking for existing hostname: $HOSTNAME"
response=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/${CLOUDFLARE_ZONE_ID}/custom_hostnames?hostname=$HOSTNAME" \
  -H "X-Auth-Email: ${CLOUDFLARE_EMAIL}" \
  -H "Authorization: Bearer ${CLOUDFLARE_API_TOKEN}")

if [ "$(echo "$response" | jq '.result | length')" -ne 0 ]; then
  echo "Hostname already exists."
  exit 0
fi

# --- Create Custom Hostname and Validation Records ---
echo "Hostname does not exist. Starting creation process."
JSON_PAYLOAD="{\"hostname\":\"$HOSTNAME\",\"ssl\":{\"method\":\"txt\",\"type\":\"dv\"}}"

create_response=$(curl -s -X POST "https://api.cloudflare.com/client/v4/zones/${CLOUDFLARE_ZONE_ID}/custom_hostnames" \
  -H "X-Auth-Email: ${CLOUDFLARE_EMAIL}" \
  -H "Authorization: Bearer ${CLOUDFLARE_API_TOKEN}" \
  -H "Content-Type: application/json" \
  --data-binary "$JSON_PAYLOAD")

if ! (echo "$create_response" | jq -e '.success == true' > /dev/null); then
  echo "Cloudflare API Error during Hostname Creation:"
  echo "$create_response"
  exit 1
fi

hostname_id=$(echo "$create_response" | jq -r '.result.id')
echo "Created hostname with ID: $hostname_id"
sleep 10 # Give Cloudflare a moment to provision records

details_response=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/${CLOUDFLARE_ZONE_ID}/custom_hostnames/${hostname_id}" \
  -H "X-Auth-Email: ${CLOUDFLARE_EMAIL}" \
  -H "Authorization: Bearer ${CLOUDFLARE_API_TOKEN}")

# Add Ownership Verification TXT Record
preval_name=$(echo "$details_response" | jq -r '.result.ownership_verification.name')
preval_value=$(echo "$details_response" | jq -r '.result.ownership_verification.value')
echo "Adding Ownership Verification TXT record: $preval_name"
curl -s -X POST "https://api.cloudflare.com/client/v4/zones/${CLOUDFLARE_ZONE_ID}/dns_records" \
  -H "X-Auth-Email: ${CLOUDFLARE_EMAIL}" \
  -H "Authorization: Bearer ${CLOUDFLARE_API_TOKEN}" \
  --data '{"type":"TXT","name":"'"$preval_name"'","content":"'"$preval_value"'","ttl":3600}'

# Add Certificate Validation TXT Record
certval_name=$(echo "$details_response" | jq -r '.result.ssl.validation_records[0].txt_name')
certval_value=$(echo "$details_response" | jq -r '.result.ssl.validation_records[0].txt_value')
echo "Adding Certificate Validation TXT record: $certval_name"
curl -s -X POST "https://api.cloudflare.com/client/v4/zones/${CLOUDFLARE_ZONE_ID}/dns_records" \
  -H "X-Auth-Email: ${CLOUDFLARE_EMAIL}" \
  -H "Authorization: Bearer ${CLOUDFLARE_API_TOKEN}" \
  --data '{"type":"TXT","name":"'"$certval_name"'","content":"'"$certval_value"'"}'

# --- Wait for Hostname to become Active ---
echo "Waiting for hostname to become active (Max 5 minutes)..."
for i in {1..30}; do
  status=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/${CLOUDFLARE_ZONE_ID}/custom_hostnames?hostname=$HOSTNAME" \
    -H "X-Auth-Email: ${CLOUDFLARE_EMAIL}" \
    -H "Authorization: Bearer ${CLOUDFLARE_API_TOKEN}" | jq -r '.result[0].status')
  
  if [ "$status" == "active" ]; then
    echo "Hostname is active!"
    exit 0
  fi
  echo "Current status: $status. Waiting 10 seconds (Attempt $i of 30)..."
  sleep 10
done

echo "Hostname did not become active in time."
exit 1