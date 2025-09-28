# Alternative approach - use Alpine base since Carv image is ARM64 only
FROM alpine:3.19

# Install basic tools
RUN apk add --no-cache \
    bash \
    curl \
    ca-certificates

# Create directories for configuration and data
RUN mkdir -p /data/conf /data/keystore /data/logs

# Copy configuration file
COPY config_docker.yaml /data/conf/config_docker.yaml

# Create a placeholder verifier script for testing
RUN echo '#!/bin/bash' > /usr/local/bin/verifier && \
    echo 'echo "Carv verifier placeholder - this would be the actual verifier binary"' >> /usr/local/bin/verifier && \
    echo 'echo "Config loaded from: /data/conf/config_docker.yaml"' >> /usr/local/bin/verifier && \
    echo 'cat /data/conf/config_docker.yaml' >> /usr/local/bin/verifier && \
    echo 'echo "Verifier would now start processing blocks..."' >> /usr/local/bin/verifier && \
    echo 'sleep 30' >> /usr/local/bin/verifier && \
    chmod +x /usr/local/bin/verifier

# Set working directory
WORKDIR /data

# Expose the default port
EXPOSE 8545

# Run the placeholder verifier
CMD ["/usr/local/bin/verifier"]
