#!/bin/bash

# Simple test script following Carv official documentation
# https://docs.carv.io/carv-ecosystem/verifier-nodes/join-mainnet-verifier-nodes/operating-a-verifier-node/running-in-cli/using-docker

echo "🚀 Testing Carv Verifier Node (Official Method)"

# Set dummy environment variables for testing
export CARV_PRIVATE_KEY="1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef"
export CARV_REWARD_CLAIMER_ADDR="0x1234567890123456789012345678901234567890"

# Update config file with environment variables
sed -i "s/\${CARV_PRIVATE_KEY}/$CARV_PRIVATE_KEY/g" config_docker.yaml
sed -i "s/\${CARV_REWARD_CLAIMER_ADDR:-0x0000000000000000000000000000000000000000}/$CARV_REWARD_CLAIMER_ADDR/g" config_docker.yaml

# Build Docker image
echo "🐳 Building Docker image..."
docker build -t carv-verifier-test .

if [ $? -eq 0 ]; then
    echo "✅ Docker image built successfully!"
    
    # Test running the container
    echo "🧪 Testing container..."
    docker run --rm -d --name carv-test \
        -v $(pwd)/config_docker.yaml:/data/conf/config_docker.yaml \
        -p 8545:8545 \
        carv-verifier-test
    
    if [ $? -eq 0 ]; then
        echo "✅ Container started successfully!"
        echo "📋 Container logs:"
        sleep 5
        docker logs carv-test
        
        echo "🛑 Stopping test container..."
        docker stop carv-test
    else
        echo "❌ Failed to start container"
    fi
else
    echo "❌ Docker build failed"
fi
