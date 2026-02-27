# GCP Server Configuration (Ansible)

This repository contains the Ansible configuration for the main GCP application server.

**Update:** Connectivity is now handled by **Cloudflare Tunnel**.

- **SSH**: requires `cloudflared` to connect.
- **Web**: handled by a Wildcard DNS record pointing to the Tunnel.

## One-Time DNS Setup

Instead of provisioning a hostname for every new app, simply create a **Wildcard CNAME** in your Cloudflare Dashboard:

1.  Go to **DNS** > **Records**.
2.  Add a `CNAME` record.
3.  Name: `*.apps` (resulting in `*.apps.yourdomain.com`).
4.  Target: `<Tunnel-UUID>.cfargotunnel.com`.
5.  Proxy status: **Proxied**.

This ensures that `myapp.apps.yourdomain.com` automatically routes to your server, where the Tunnel passes it to Caddy, and Caddy routes it to the correct container.

## Manual Execution (Local)

To run Ansible locally, you must have `cloudflared` installed and your SSH config set up to proxy the connection.

1.  **Configure SSH**:
    Add this to `~/.ssh/config`:
    ```
    Host gcp-server
      HostName ssh.yourdomain.com
      User dev
      IdentityFile ~/.ssh/id_ed25519_gcp
      ProxyCommand /usr/local/bin/cloudflared access ssh --hostname %h
    ```
2.  **Run Playbook**:
    Edit the `inventory` file to use `ansible_host=gcp-server` (the Host alias from your config).
    ```bash
    ansible-playbook -i inventory playbook.yml --ask-vault-pass
    ```

## Secrets

The `cloudflare_origin_cert` and `cloudflare_origin_key` are **no longer required** in `vars/secrets.yml` as TLS is terminated at the Cloudflare Edge.

## VPN & Captive Portal Bypass

This server is configured to bypass strict firewalls and captive portals by hosting a VPN on port 53 (DNS).

To achieve this without port conflicts, we use a custom-built version of `sslh` (UDP multiplexer) that listens on `0.0.0.0:53`. It analyzes incoming UDP packets and seamlessly routes them:

1. **WireGuard**: If the packet matches a WireGuard handshake (`0x01`) or data packet (`0x04`), it is sent to the local WireGuard container (`51820`).
2. **Iodine (DNS Tunnel)**: All other UDP traffic on port 53 is assumed to be raw DNS queries and is forwarded to the local Iodine container (`5353`).

**Connecting:**

- **Standard VPN:** Connect to `vpn.yourdomain.com:51820` (or fallback ports `443`, `80`, `4500`).
- **Captive Portal Bypass (WireGuard):** Connect to `vpn.yourdomain.com:53`.
- **Deep DPI Bypass (Iodine):** Connect your local Iodine client to `t.yourdomain.com`.
