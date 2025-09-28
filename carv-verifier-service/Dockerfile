# Simple Carv Verifier Node Docker setup following official documentation
FROM carvprotocol/verifier:mainnet

# Create directories for configuration and data
RUN mkdir -p /data/conf /data/keystore /data/logs

# Copy configuration file
COPY config_docker.yaml /data/conf/config_docker.yaml

# Set working directory
WORKDIR /data

# Expose the default port
EXPOSE 8545

# Use the default entrypoint from the Carv image
# The image should already have the verifier binary and proper entrypoint
