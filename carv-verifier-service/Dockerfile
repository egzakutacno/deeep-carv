# Simple Carv Verifier Docker setup following official documentation
# Based on https://github.com/carv-protocol/verifier

# Build Carv Verifier from Source
FROM golang:1.21-alpine AS builder

# Install build dependencies
RUN apk add --no-cache git make

# Clone and build the Carv verifier
WORKDIR /build
RUN git clone https://github.com/carv-protocol/verifier.git .
RUN make build

# Runtime stage
FROM alpine:3.19

# Install runtime dependencies
RUN apk add --no-cache \
    bash \
    curl \
    ca-certificates

# Create directories for configuration and data
RUN mkdir -p /data/conf /data/keystore /data/logs

# Copy built Carv verifier binary
COPY --from=builder /build/bin/verifier /usr/local/bin/verifier
RUN chmod +x /usr/local/bin/verifier

# Copy configuration file
COPY config_docker.yaml /data/conf/config_docker.yaml

# Set working directory
WORKDIR /data

# Expose the default port
EXPOSE 8545

# Run the Carv verifier directly
CMD ["/usr/local/bin/verifier", "-conf", "/data/conf/config_docker.yaml"]
