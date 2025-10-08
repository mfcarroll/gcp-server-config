# GCP Server Configuration (Ansible)

This repository contains the Ansible configuration for the main GCP application server. It is responsible for installing core software (Docker, Caddy), managing the reverse proxy, and deploying all containerized applications via a reusable GitHub workflow.

## Architecture Overview
This setup uses a decoupled architecture to manage services. The main `playbook.yml` is generic and does not need to be modified when adding new applications.

* **Reusable Workflow**: The `.github/workflows/reusable-deploy.yml` file contains the master CI/CD logic for building, pushing, and deploying applications.
* **Dynamic Configuration**: The server uses a top-level `compose.yml` that is dynamically configured by Ansible to include all individual application compose files from the `/opt/docker/services/` directory.
* **Automated Routing**: A templated `Caddyfile` uses wildcards to automatically route traffic to the correct backend service based on the subdomain, requiring no changes for new apps.

## Secrets Management with Ansible Vault

All server-wide secrets are stored in `vars/secrets.yml`. This file is encrypted and safe to commit to Git.

### Initial Setup

To create the secrets file for the first time:
```bash
ansible-vault create vars/secrets.yml
```
You will be prompted to create a password. This password must be stored as the `ANSIBLE_VAULT_PASSWORD` secret in the GitHub Actions settings of any application repository that needs to trigger a deployment.

### Editing Secrets

To edit the encrypted secrets file:
```bash
ansible-vault edit vars/secrets.yml
```

The following secrets need to be defined in `vars/secrets.yml`:
* `cloudflare_origin_cert`: The Cloudflare Origin Certificate (PEM format), correctly indented.
* `cloudflare_origin_key`: The Cloudflare Origin Private Key (PEM format), correctly indented.

## Manual Execution
Running the playbook manually is only necessary for initial server setup or for debugging fundamental configuration changes. Application deployments are handled automatically by the reusable workflow.

To run the playbook from your local machine:
```bash
ansible-playbook -i inventory playbook.yml --ask-vault-pass
```

## Secrets Management
All server-wide secrets (like the Cloudflare Origin Certificate) are stored in the encrypted `vars/secrets.yml`. To edit this file, use the command:
```bash
ansible-vault edit vars/secrets.yml
```
The vault password must be stored as the `ANSIBLE_VAULT_PASSWORD` secret in the GitHub settings of any application repository that needs to trigger a deployment.
```