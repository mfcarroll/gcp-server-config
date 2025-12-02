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
