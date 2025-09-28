# Build Carv Verifier from Source with Riptide Integration
# Based on https://github.com/carv-protocol/verifier

# ----------------------------------------
# Builder Stage - Build Carv Verifier
# ----------------------------------------
FROM golang:1.21-alpine AS carv-builder

# Install build dependencies
RUN apk add --no-cache git make

# Clone and build the Carv verifier
WORKDIR /build
RUN git clone https://github.com/carv-protocol/verifier.git .
RUN make build

# ----------------------------------------
# Node.js Builder Stage - Build Riptide Service
# ----------------------------------------
FROM node:22-alpine AS riptide-builder
RUN apk add --no-cache libc6-compat
WORKDIR /app
COPY package.json package-lock.json ./
COPY tsconfig.json ./
COPY tsup.config.ts ./
COPY src ./src
RUN npm install
RUN npm run build
RUN npm prune --omit=dev

# ----------------------------------------
# Final Runtime Stage
# ----------------------------------------
FROM alpine:3.19 AS runtime

# Install runtime dependencies
RUN apk add --no-cache \
    bash \
    curl \
    ca-certificates \
    nodejs \
    npm

# Create directories
RUN mkdir -p /data/conf /data/keystore /data/logs /riptide

# Copy built Carv verifier binary
COPY --from=carv-builder /build/bin/verifier /usr/local/bin/verifier
RUN chmod +x /usr/local/bin/verifier

# Copy Riptide service
COPY --from=riptide-builder /app/dist /riptide/dist
COPY --from=riptide-builder /app/node_modules /riptide/node_modules
COPY --from=riptide-builder /app/package.json /riptide/package.json

# Copy configuration files
COPY config_docker.yaml /data/conf/config_docker.yaml
COPY riptide.config.json /riptide/riptide.config.json

# Install Riptide CLI
RUN npm install -g @deeep-network/riptide

# Set working directory
WORKDIR /data

# Expose ports
EXPOSE 8545 3000

# Use Riptide as entrypoint
WORKDIR /riptide
ENTRYPOINT ["riptide", "start", "--config", "/riptide/riptide.config.json", "--hooks", "/riptide/dist/hooks.js"]
