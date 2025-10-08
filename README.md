# GCP Server Configuration (Ansible)

This repository contains the Ansible configuration for the main GCP application server. It is responsible for installing all necessary software (Docker, Caddy), managing the reverse proxy, and deploying all containerized applications using Docker Compose.

This configuration is triggered automatically by the CI/CD pipeline in each application's repository. It can also be run manually for initial setup or debugging.

## Structure

* **`playbook.yml`**: The main Ansible playbook that orchestrates all tasks.
* **`inventory`**: Defines the server's IP address and common variables.
* **`templates/`**: Contains Jinja2 templates for configuration files that are generated and copied to the server.
    * `Caddyfile.j2`: The dynamic configuration for the Caddy reverse proxy.
    * `docker-compose.yml.j2`: The main Docker Compose file that defines all running services.
* **`caddy/`**: Contains the `Dockerfile` for building the custom Caddy image with the Cloudflare plugin.
* **`vars/secrets.yml`**: An Ansible Vault encrypted file for storing all secrets, such as API tokens and certificates.

## Secrets Management with Ansible Vault

All secrets are stored in `vars/secrets.yml` and encrypted. This file is safe to commit to Git.

### Initial Setup

To create the secrets file for the first time:
```bash
ansible-vault create vars/secrets.yml
```
You will be prompted to create a password. This password must be stored as the `ANSIBLE_VAULT_PASSWORD` secret in the application repositories' GitHub Actions settings.

### Editing Secrets

To edit the encrypted secrets file:
```bash
ansible-vault edit vars/secrets.yml
```

The following secrets need to be defined in `vars/secrets.yml`:
* `cloudflare_origin_cert`: The Cloudflare Origin Certificate (PEM format).
* `cloudflare_origin_key`: The Cloudflare Origin Private Key (PEM format).

## Running Manually

To run the playbook from your local machine, you need to provide the vault password.

```bash
ansible-playbook -i inventory playbook.yml --ask-vault-pass
```