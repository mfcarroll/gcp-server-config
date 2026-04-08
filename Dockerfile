FROM caddy:2.10.2-builder-alpine AS builder
# Using pinned commit d62c80d for v2.10.0-naive compatibility
RUN xcaddy build --with github.com/caddyserver/forwardproxy=github.com/klzgrad/forwardproxy@d62c80d

FROM caddy:2.10.2-alpine
COPY --from=builder /usr/bin/caddy /usr/bin/caddy