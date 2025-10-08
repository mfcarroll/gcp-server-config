# GCP Server Configuration (Ansible)

This repository contains the Ansible configuration for the main GCP application server. It is responsible for installing all necessary software (Docker, Caddy), managing the reverse proxy, and deploying all containerized applications using a decoupled Docker Compose setup.

This configuration is triggered automatically by the CI/CD pipeline in each individual application's repository and should rarely need to be run manually.

## Decoupled Architecture

This setup uses a decoupled architecture to manage services, which means **this repository does not need to be modified** to add, remove, or update individual applications.

The system works as follows:
* The main `templates/docker-compose.yml.j2` file acts as a "collector." It defines shared services (like Caddy) and uses the `include` directive to automatically load all `.yml` files from the `/opt/docker/services/` directory on the server.
* Each application is responsible for deploying its own `compose.yml` file into this directory via its own CI/CD pipeline.
* This creates a clean separation of concerns where the server configuration is generic, and each application manages its own deployment details.

## Structure

* **`playbook.yml`**: The main Ansible playbook that orchestrates all server state.
* **`inventory`**: Defines the server's IP address and common, non-sensitive variables.
* **`templates/`**: Contains Jinja2 templates for global configuration files.
    * `Caddyfile.j2`: The dynamic configuration for the Caddy reverse proxy. It uses wildcards to route traffic to the correct backend service based on the subdomain.
    * `docker-compose.yml.j2`: The top-level Docker Compose file that includes all individual service configurations.
* **`caddy/`**: Contains the `Dockerfile` for building the custom, lightweight Caddy image that includes the Cloudflare plugin.
* **`vars/secrets.yml`**: An Ansible Vault encrypted file for storing all server-wide secrets, such as the Cloudflare Origin Certificate.

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

Running the playbook manually is only necessary for initial server setup or for debugging fundamental configuration changes. Application deployments are handled automatically.

To run the playbook from your local machine:
```bash
ansible-playbook -i inventory playbook.yml --ask-vault-pass
```