# Stage 1: Build the custom Caddy binary
FROM caddy:2-builder AS builder

RUN xcaddy build \
    --with github.com/caddy-dns/cloudflare

# Stage 2: Create the final, lightweight image
FROM caddy:2-alpine

# Copy the custom-built Caddy binary from the builder stage
COPY --from=builder /usr/bin/caddy /usr/bin/caddy