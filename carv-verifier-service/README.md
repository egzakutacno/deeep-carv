# Carv Verifier Node with Riptide Orchestration

This project builds the **actual Carv Verifier Node from source** and integrates it with the `@deeep-network/riptide` SDK for HashiCorp Nomad orchestration. Based on the [official Carv verifier repository](https://github.com/carv-protocol/verifier), this provides a robust and scalable solution for running Carv verifier nodes in a containerized environment.

## 🎯 What This Does

- **Builds Carv Verifier from Source**: Uses Go 1.21+ to compile the actual Carv verifier binary
- **Integrates with Riptide**: Provides lifecycle management and orchestration capabilities
- **Production Ready**: Creates a Docker image ready for NerdNode Nomad deployment
- **No Platform Issues**: Builds everything from source, avoiding ARM64/AMD64 conflicts

## 🏗️ Architecture

The service uses a **multi-stage Docker build**:

1. **Carv Builder Stage**: 
   - Uses `golang:1.21-alpine`
   - Clones and builds Carv verifier from [official repository](https://github.com/carv-protocol/verifier)
   - Compiles the actual `verifier` binary

2. **Riptide Builder Stage**:
   - Uses `node:22-alpine` 
   - Builds TypeScript Riptide service
   - Creates lifecycle management hooks

3. **Final Runtime Stage**:
   - Uses `alpine:3.19`
   - Combines Carv verifier binary + Riptide service
   - Ready for production deployment

## 📋 Prerequisites

- Docker (for building and running containers)
- Node.js 22+ and npm/pnpm
- HashiCorp Nomad CLI
- A Carv private key for the verifier node

## 🚀 Quick Start

### 1. Set Environment Variables

```bash
export CARV_PRIVATE_KEY="your_private_key_here"
export CARV_REWARD_CLAIMER_ADDR="0xYourRewardClaimerAddress"  # optional, for reward claiming
export CARV_CHAIN_ID="42161"  # optional, defaults to Arbitrum mainnet
export CARV_RPC_URL="https://arb1.arbitrum.io/rpc"  # optional, defaults to Arbitrum
```

### 2. Install Dependencies

```bash
npm install
```

### 3. Build and Deploy

```bash
# Make scripts executable
chmod +x deploy.sh manage.sh

# Deploy the service
./deploy.sh
```

### 4. Test the Setup

```bash
# Test the complete build and integration
./test-carv.sh
```

This will:
- Build Carv verifier from source
- Build Riptide service
- Create combined Docker image
- Test the integration
- Show comprehensive logs

### 5. Manage the Service

```bash
# Check status
./manage.sh status

# View logs
./manage.sh logs

# Check health
./manage.sh health

# Restart service
./manage.sh restart
```

## 🔧 Configuration

### Environment Variables

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `CARV_PRIVATE_KEY` | ✅ | - | Private key for the Carv verifier node wallet |
| `CARV_REWARD_CLAIMER_ADDR` | ❌ | `0x0000...` | Reward claimer address for the verifier node |
| `CARV_CHAIN_ID` | ❌ | `42161` | Chain ID (42161 for Arbitrum mainnet) |
| `CARV_RPC_URL` | ❌ | `https://arb1.arbitrum.io/rpc` | RPC URL for Arbitrum network |
| `NODE_ENV` | ❌ | `production` | Node environment |

### Configuration Files

- **`config_docker.yaml`**: Carv verifier node configuration
- **`riptide.config.json`**: Riptide service configuration
- **`carv-verifier.nomad`**: Nomad job specification

## 🐳 Docker Usage

### Build the Image

```bash
npm run build:docker
```

### Run Locally

```bash
docker run -e CARV_PRIVATE_KEY=your_key_here reef-carv-verifier-service
```

## 📊 Nomad Integration

### Job Specification

The `carv-verifier.nomad` file defines:
- Resource allocation (1 CPU, 2GB RAM, 10GB disk)
- Network ports (8545 for HTTP, 9090 for metrics)
- Health checks and service discovery
- Volume mounts for persistent data
- Restart and rescheduling policies

### Deploy to Nomad

```bash
# Deploy the job
nomad job run carv-verifier.nomad

# Check job status
nomad job status carv-verifier

# View logs
nomad logs -job carv-verifier

# Scale the job
nomad job scale carv-verifier 3
```

## 🔄 Lifecycle Management

The service implements the following lifecycle hooks:

### `installSecrets`
- Validates required secrets (CARV_PRIVATE_KEY)
- Updates configuration file with private key
- Sets up secure configuration

### `start`
- Launches the Carv verifier node process
- Configures logging and error handling
- Monitors process health

### `health`
- Checks if the verifier process is running
- Validates process responsiveness
- Returns health status for Nomad

### `stop`
- Gracefully shuts down the verifier process
- Handles SIGTERM and SIGKILL signals
- Cleans up resources

## 📈 Monitoring

### Health Checks

- **Process Health**: Checks if the verifier process is alive
- **HTTP Health**: Validates HTTP endpoint responsiveness
- **TCP Health**: Ensures port connectivity

### Logging

- Structured JSON logging
- Log rotation (10 files, 10MB each)
- Integration with Nomad log aggregation

### Metrics

- Prometheus metrics endpoint on port 9090
- Custom metrics for verifier node performance
- Integration with monitoring systems

## 🛠️ Development

### Local Development

```bash
# Install dependencies
npm install

# Build the service
npm run build

# Validate configuration
npm run validate

# Start locally
npm start
```

### Testing

```bash
# Type check
npm run type-check

# Validate hooks
npm run validate

# Build and test Docker image
npm run build:docker
```

## 📁 Project Structure

```
carv-verifier-service/
├── src/
│   └── hooks.ts              # Lifecycle hooks implementation
├── config_docker.yaml        # Carv verifier node configuration
├── riptide.config.json       # Riptide service configuration
├── carv-verifier.nomad       # Nomad job specification
├── Dockerfile                # Multi-stage Docker build
├── package.json              # Node.js dependencies and scripts
├── deploy.sh                 # Deployment script
├── manage.sh                 # Management script
└── README.md                 # This file
```

## 🔒 Security

- Private keys are injected via environment variables
- Configuration files are updated at runtime
- Container runs as non-root user (uid 1005)
- Secure volume mounts for sensitive data
- No secrets stored in Docker images

## 🚨 Troubleshooting

### Common Issues

1. **Private Key Not Set**
   ```bash
   export CARV_PRIVATE_KEY="your_private_key_here"
   ```

2. **Docker Build Fails**
   ```bash
   # Check Docker is running
   docker --version
   
   # Clean up and rebuild
   docker system prune -f
   npm run build:docker
   ```

3. **Nomad Job Fails**
   ```bash
   # Check job status
   nomad job status carv-verifier
   
   # View allocation details
   nomad alloc status <allocation-id>
   
   # Check logs
   nomad logs -job carv-verifier
   ```

4. **Health Checks Failing**
   ```bash
   # Check if ports are accessible
   nomad alloc exec <allocation-id> netstat -tlnp
   
   # Verify process is running
   nomad alloc exec <allocation-id> ps aux | grep carv-verifier
   ```

### Logs and Debugging

```bash
# View service logs
./manage.sh logs

# Check Nomad logs
nomad logs -job carv-verifier -stderr

# Debug allocation
nomad alloc exec <allocation-id> /bin/bash
```

## 📚 Additional Resources

- [Carv Documentation](https://docs.carv.io)
- [Riptide SDK](https://www.npmjs.com/package/@deeep-network/riptide)
- [HashiCorp Nomad](https://www.nomadproject.io/docs)
- [Docker Documentation](https://docs.docker.com)

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.
