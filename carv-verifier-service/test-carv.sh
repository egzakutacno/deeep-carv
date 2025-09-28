#!/bin/bash

# Simple test script for Carv Verifier built from source
# Based on https://github.com/carv-protocol/verifier

echo "🚀 Testing Carv Verifier Node (Built from Source)"

# Navigate to the service directory
cd "$(dirname "$0")"

# Set dummy environment variables for testing
export CARV_PRIVATE_KEY="1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef"
export CARV_REWARD_CLAIMER_ADDR="0x1234567890123456789012345678901234567890"

# Clean up any existing containers
echo "🧹 Cleaning up any existing test containers..."
docker stop carv-verifier-test > /dev/null 2>&1
docker rm carv-verifier-test > /dev/null 2>&1

# Build the Docker image (this will build Carv from source)
echo "🐳 Building Docker image (this may take a few minutes)..."
echo "   - Building Carv verifier from https://github.com/carv-protocol/verifier"
echo "   - Creating simple runtime image"

docker build --platform ${DOCKER_PLATFORM:-linux/amd64} --progress=plain -t carv-verifier:test .

if [ $? -ne 0 ]; then
    echo "❌ Docker build failed"
    exit 1
fi

echo "✅ Docker image built successfully: carv-verifier:test"

# Create necessary directories
mkdir -p configs keystore

# Update config file with environment variables
echo "🔧 Updating configuration with test values..."
sed -i "s/\${CARV_PRIVATE_KEY}/$CARV_PRIVATE_KEY/g" config_docker.yaml
sed -i "s/\${CARV_REWARD_CLAIMER_ADDR:-0x0000000000000000000000000000000000000000}/$CARV_REWARD_CLAIMER_ADDR/g" config_docker.yaml

# Run the Docker container
echo "▶️ Running Docker container..."
docker run -d --name carv-verifier-test \
  -v "$(pwd)/config_docker.yaml:/data/conf/config_docker.yaml" \
  -p 8545:8545 \
  carv-verifier:test

if [ $? -ne 0 ]; then
    echo "❌ Docker container failed to start"
    exit 1
fi

echo "✅ Docker container 'carv-verifier-test' started."
echo "ℹ️ Waiting for 15 seconds to allow the services to initialize..."
sleep 15

# Check container logs
echo "📄 Checking container logs:"
docker logs carv-verifier-test

# Check if the container is still running
if docker ps -f name=carv-verifier-test | grep -q carv-verifier-test; then
    echo "✅ Carv verifier node container is running."
    echo "🔗 Carv verifier should be available on port 8545"
    
    # Test if service is responding
    echo "🔍 Testing service endpoint..."
    
    # Test Carv verifier endpoint
    if curl -s http://localhost:8545 > /dev/null 2>&1; then
        echo "✅ Carv verifier service is responding"
    else
        echo "⚠️ Carv verifier service may not be ready yet"
    fi
else
    echo "❌ Carv verifier node container is not running. Check logs for errors."
fi

# Keep container running for a bit to see more logs
echo "⏳ Keeping container running for 30 seconds to observe behavior..."
sleep 30

# Check logs again
echo "📄 Final container logs:"
docker logs carv-verifier-test

# Clean up
echo "🧹 Cleaning up..."
docker stop carv-verifier-test > /dev/null 2>&1
docker rm carv-verifier-test > /dev/null 2>&1
docker rmi carv-verifier:test > /dev/null 2>&1
echo "🗑️ Cleanup complete."

echo "🎉 Test finished."
echo ""
echo "💡 This test built the actual Carv verifier from source!"
echo "   For production use, you would:"
echo "   1. Replace the dummy private key with a real one"
echo "   2. Set proper reward claimer address"
echo "   3. Deploy this Docker image anywhere you want"
