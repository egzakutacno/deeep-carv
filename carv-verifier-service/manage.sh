#!/bin/bash

# Carv Verifier Node Management Script
# This script provides commands to manage the Carv verifier node

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
JOB_NAME="carv-verifier"
SERVICE_NAME="carv-verifier-service"

# Function to display usage
usage() {
    echo -e "${BLUE}Carv Verifier Node Management Script${NC}"
    echo ""
    echo "Usage: $0 [COMMAND]"
    echo ""
    echo "Commands:"
    echo "  status      - Show job status"
    echo "  logs        - View job logs"
    echo "  restart     - Restart the job"
    echo "  stop        - Stop the job"
    echo "  start       - Start the job"
    echo "  scale N     - Scale to N instances"
    echo "  health      - Check service health"
    echo "  validate    - Validate service configuration"
    echo "  build       - Build Docker image"
    echo "  deploy      - Deploy to Nomad"
    echo "  help        - Show this help message"
    echo ""
}

# Function to show job status
show_status() {
    echo -e "${BLUE}📊 Job Status:${NC}"
    nomad job status $JOB_NAME
    echo ""
    echo -e "${BLUE}📋 Allocation Status:${NC}"
    nomad job allocs $JOB_NAME
}

# Function to view logs
view_logs() {
    echo -e "${BLUE}📋 Viewing logs for job: $JOB_NAME${NC}"
    nomad logs -job $JOB_NAME
}

# Function to restart job
restart_job() {
    echo -e "${YELLOW}🔄 Restarting job: $JOB_NAME${NC}"
    nomad job restart $JOB_NAME
    echo -e "${GREEN}✅ Job restart initiated${NC}"
}

# Function to stop job
stop_job() {
    echo -e "${YELLOW}⏹️  Stopping job: $JOB_NAME${NC}"
    nomad job stop $JOB_NAME
    echo -e "${GREEN}✅ Job stopped${NC}"
}

# Function to start job
start_job() {
    echo -e "${YELLOW}▶️  Starting job: $JOB_NAME${NC}"
    nomad job run carv-verifier.nomad
    echo -e "${GREEN}✅ Job started${NC}"
}

# Function to scale job
scale_job() {
    local count=$1
    if [ -z "$count" ]; then
        echo -e "${RED}❌ Please specify the number of instances${NC}"
        echo "Usage: $0 scale <number>"
        exit 1
    fi
    
    echo -e "${YELLOW}📈 Scaling job to $count instances${NC}"
    nomad job scale $JOB_NAME $count
    echo -e "${GREEN}✅ Job scaled to $count instances${NC}"
}

# Function to check health
check_health() {
    echo -e "${BLUE}🏥 Checking service health...${NC}"
    
    # Check if job is running
    if nomad job status $JOB_NAME | grep -q "running"; then
        echo -e "${GREEN}✅ Job is running${NC}"
    else
        echo -e "${RED}❌ Job is not running${NC}"
        return 1
    fi
    
    # Check allocations
    local allocs=$(nomad job allocs $JOB_NAME | grep -c "running" || true)
    if [ "$allocs" -gt 0 ]; then
        echo -e "${GREEN}✅ $allocs allocation(s) running${NC}"
    else
        echo -e "${RED}❌ No running allocations${NC}"
        return 1
    fi
    
    echo -e "${GREEN}✅ Service is healthy${NC}"
}

# Function to validate service
validate_service() {
    echo -e "${YELLOW}🔍 Validating service configuration...${NC}"
    npm run validate
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ Service validation passed${NC}"
    else
        echo -e "${RED}❌ Service validation failed${NC}"
        exit 1
    fi
}

# Function to build Docker image
build_image() {
    echo -e "${YELLOW}🔨 Building Docker image...${NC}"
    npm run build:docker
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ Docker image built successfully${NC}"
    else
        echo -e "${RED}❌ Docker build failed${NC}"
        exit 1
    fi
}

# Function to deploy
deploy() {
    echo -e "${YELLOW}🚀 Deploying to Nomad...${NC}"
    ./deploy.sh
}

# Main script logic
case "$1" in
    "status")
        show_status
        ;;
    "logs")
        view_logs
        ;;
    "restart")
        restart_job
        ;;
    "stop")
        stop_job
        ;;
    "start")
        start_job
        ;;
    "scale")
        scale_job "$2"
        ;;
    "health")
        check_health
        ;;
    "validate")
        validate_service
        ;;
    "build")
        build_image
        ;;
    "deploy")
        deploy
        ;;
    "help"|"--help"|"-h"|"")
        usage
        ;;
    *)
        echo -e "${RED}❌ Unknown command: $1${NC}"
        echo ""
        usage
        exit 1
        ;;
esac
