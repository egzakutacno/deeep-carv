#!/bin/bash

# Test script for Carv Verifier built from source with Riptide integration
# Based on https://github.com/carv-protocol/verifier

echo "🚀 Testing Carv Verifier Node (Built from Source with Riptide)"

# Navigate to the service directory
cd "$(dirname "$0")"

# Set dummy environment variables for testing
export CARV_PRIVATE_KEY="1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef"
export CARV_REWARD_CLAIMER_ADDR="0x1234567890123456789012345678901234567890"

# Clean up any existing containers
echo "🧹 Cleaning up any existing test containers..."
docker stop carv-verifier-test > /dev/null 2>&1
docker rm carv-verifier-test > /dev/null 2>&1

# Build the Docker image (this will build Carv from source + Riptide)
echo "🐳 Building Docker image (this may take a few minutes)..."
echo "   - Building Carv verifier from https://github.com/carv-protocol/verifier"
echo "   - Building Riptide service"
echo "   - Creating final image with both components"

docker build --platform ${DOCKER_PLATFORM:-linux/amd64} --progress=plain -t carv-verifier-riptide:test .

if [ $? -ne 0 ]; then
    echo "❌ Docker build failed"
    exit 1
fi

echo "✅ Docker image built successfully: carv-verifier-riptide:test"

# Create necessary directories
mkdir -p configs keystore

# Run the Docker container
echo "▶️ Running Docker container with Riptide orchestration..."
docker run -d --name carv-verifier-test \
  -v "$(pwd)/configs:/data/conf" \
  -v "$(pwd)/keystore:/data/keystore" \
  -e CARV_PRIVATE_KEY="$CARV_PRIVATE_KEY" \
  -e CARV_REWARD_CLAIMER_ADDR="$CARV_REWARD_CLAIMER_ADDR" \
  -p 3000:3000 \
  -p 8545:8545 \
  carv-verifier-riptide:test

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
    echo "🌐 Riptide service should be available on port 3000"
    echo "🔗 Carv verifier should be available on port 8545"
    
    # Test if services are responding
    echo "🔍 Testing service endpoints..."
    
    # Test Riptide health endpoint
    if curl -s http://localhost:3000/health > /dev/null 2>&1; then
        echo "✅ Riptide service is responding"
    else
        echo "⚠️ Riptide service may not be ready yet"
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
docker rmi carv-verifier-riptide:test > /dev/null 2>&1
echo "🗑️ Cleanup complete."

echo "🎉 Test finished."
echo ""
echo "💡 This test built the actual Carv verifier from source and integrated it with Riptide!"
echo "   For production use with NerdNode, you would:"
echo "   1. Replace the dummy private key with a real one"
echo "   2. Set proper reward claimer address"
echo "   3. Deploy using Nomad with this Docker image"
