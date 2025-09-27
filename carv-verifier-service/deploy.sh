#!/bin/bash

# Carv Verifier Node Deployment Script
# This script builds and deploys the Carv verifier node using Riptide and Nomad

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
SERVICE_NAME="carv-verifier-service"
DOCKER_IMAGE="reef-carv-verifier-service"
NOMAD_JOB_FILE="carv-verifier.nomad"

echo -e "${BLUE}🚀 Starting Carv Verifier Node Deployment${NC}"

# Check prerequisites
echo -e "${YELLOW}📋 Checking prerequisites...${NC}"

if ! command -v docker &> /dev/null; then
    echo -e "${RED}❌ Docker is not installed${NC}"
    exit 1
fi

if ! command -v nomad &> /dev/null; then
    echo -e "${RED}❌ Nomad CLI is not installed${NC}"
    exit 1
fi

if ! command -v node &> /dev/null; then
    echo -e "${RED}❌ Node.js is not installed${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Prerequisites check passed${NC}"

# Check if private key is provided
if [ -z "$CARV_PRIVATE_KEY" ]; then
    echo -e "${RED}❌ CARV_PRIVATE_KEY environment variable is required${NC}"
    echo -e "${YELLOW}💡 Set it with: export CARV_PRIVATE_KEY=your_private_key_here${NC}"
    exit 1
fi

# Install dependencies
echo -e "${YELLOW}📦 Installing dependencies...${NC}"
npm install

# Build the service
echo -e "${YELLOW}🔨 Building the service...${NC}"
npm run build

# Validate the service
echo -e "${YELLOW}🔍 Validating the service...${NC}"
npm run validate

if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Service validation failed${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Service validation passed${NC}"

# Build Docker image
echo -e "${YELLOW}🐳 Building Docker image...${NC}"
npm run build:docker

if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Docker build failed${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Docker image built successfully${NC}"

# Create Nomad volume if it doesn't exist
echo -e "${YELLOW}💾 Setting up Nomad volume...${NC}"
nomad volume status carv-verifier-data &> /dev/null || {
    echo -e "${YELLOW}📁 Creating Nomad volume...${NC}"
    # Note: You may need to configure this based on your Nomad setup
    echo -e "${YELLOW}⚠️  Please ensure the 'carv-verifier-data' volume exists in your Nomad cluster${NC}"
}

# Deploy to Nomad
echo -e "${YELLOW}🚀 Deploying to Nomad...${NC}"
nomad job run $NOMAD_JOB_FILE

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Deployment successful!${NC}"
    echo -e "${BLUE}📊 Check status with: nomad job status carv-verifier${NC}"
    echo -e "${BLUE}📋 View logs with: nomad logs -job carv-verifier${NC}"
else
    echo -e "${RED}❌ Deployment failed${NC}"
    exit 1
fi

echo -e "${GREEN}🎉 Carv Verifier Node deployment completed!${NC}"
