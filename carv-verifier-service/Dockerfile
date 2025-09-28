# DeEEP Network Service for carv-verifier-service

# ----------------------------------------
# Builder Stage
# ----------------------------------------
FROM node:22-alpine AS builder
RUN apk add --no-cache libc6-compat
WORKDIR /app
COPY package.json package-lock.json ./

# Copy source code and config
COPY tsconfig.json ./
COPY tsup.config.ts ./
COPY src ./src

# Build the application
RUN npm install
RUN npm run build
RUN npm prune --omit=dev

# ----------------------------------------
# Third-party Base
# ----------------------------------------
FROM node:22-alpine AS carv-verifier-service-base

# Install system dependencies
RUN apk add --no-cache \
    curl \
    bash \
    procps \
    ca-certificates \
    wget \
    unzip

# For now, we'll create a dummy carv-verifier script to test the build
# In production, you'll need to get the actual Carv verifier binary
RUN echo '#!/bin/sh' > /usr/local/bin/carv-verifier && \
    echo 'echo "Carv verifier node placeholder - replace with actual binary"' >> /usr/local/bin/carv-verifier && \
    chmod +x /usr/local/bin/carv-verifier

# Create directories for Carv verifier node
RUN mkdir -p /data/conf /data/keystore /data/logs

WORKDIR /app

# Copy Carv verifier node configuration
COPY config_docker.yaml /data/conf/config_docker.yaml

# Add any carv-verifier-service-specific setup here
# Example: Download binaries, create users, set up directories

# ----------------------------------------
# Riptide Runtime Layer
# ----------------------------------------
FROM carv-verifier-service-base AS riptide
RUN addgroup -g 1005 riptide && adduser -u 1005 -G riptide -D riptide
COPY --from=quay.io/nerdnode/riptide:latest /usr/local/bin/riptide /usr/local/bin/riptide
COPY --from=quay.io/nerdnode/riptide:latest /riptide-runtime/ /riptide-runtime/
RUN chmod +x /usr/local/bin/riptide
ENV PATH="/usr/local/bin:$PATH"
RUN mkdir -p /riptide && chown -R riptide:riptide /riptide
COPY --from=builder --chown=riptide:riptide /app/dist /riptide/dist
COPY --from=builder --chown=riptide:riptide /app/node_modules /riptide/node_modules
COPY --from=builder --chown=riptide:riptide /app/package.json /riptide/package.json
COPY --chown=riptide:riptide riptide.config.json /riptide/riptide.config.json

EXPOSE 3000
WORKDIR /riptide
USER riptide
ENV NODE_ENV=production
ENTRYPOINT ["/usr/local/bin/riptide"]
CMD ["start", "--config", "/riptide/riptide.config.json", "--hooks", "/riptide/dist/hooks.js"]
