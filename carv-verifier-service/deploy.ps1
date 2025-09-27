# Carv Verifier Node Deployment Script (PowerShell)
# This script builds and deploys the Carv verifier node using Riptide and Nomad

param(
    [string]$PrivateKey = $env:CARV_PRIVATE_KEY
)

# Configuration
$ServiceName = "carv-verifier-service"
$DockerImage = "reef-carv-verifier-service"
$NomadJobFile = "carv-verifier.nomad"

Write-Host "🚀 Starting Carv Verifier Node Deployment" -ForegroundColor Blue

# Check prerequisites
Write-Host "📋 Checking prerequisites..." -ForegroundColor Yellow

if (!(Get-Command docker -ErrorAction SilentlyContinue)) {
    Write-Host "❌ Docker is not installed" -ForegroundColor Red
    exit 1
}

if (!(Get-Command nomad -ErrorAction SilentlyContinue)) {
    Write-Host "❌ Nomad CLI is not installed" -ForegroundColor Red
    exit 1
}

if (!(Get-Command node -ErrorAction SilentlyContinue)) {
    Write-Host "❌ Node.js is not installed" -ForegroundColor Red
    exit 1
}

Write-Host "✅ Prerequisites check passed" -ForegroundColor Green

# Check if private key is provided
if ([string]::IsNullOrEmpty($PrivateKey)) {
    Write-Host "❌ CARV_PRIVATE_KEY environment variable is required" -ForegroundColor Red
    Write-Host "💡 Set it with: `$env:CARV_PRIVATE_KEY='your_private_key_here'" -ForegroundColor Yellow
    exit 1
}

# Install dependencies
Write-Host "📦 Installing dependencies..." -ForegroundColor Yellow
npm install

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Failed to install dependencies" -ForegroundColor Red
    exit 1
}

# Build the service
Write-Host "🔨 Building the service..." -ForegroundColor Yellow
npm run build

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Service build failed" -ForegroundColor Red
    exit 1
}

# Validate the service
Write-Host "🔍 Validating the service..." -ForegroundColor Yellow
npm run validate

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Service validation failed" -ForegroundColor Red
    exit 1
}

Write-Host "✅ Service validation passed" -ForegroundColor Green

# Build Docker image
Write-Host "🐳 Building Docker image..." -ForegroundColor Yellow
npm run build:docker

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Docker build failed" -ForegroundColor Red
    exit 1
}

Write-Host "✅ Docker image built successfully" -ForegroundColor Green

# Create Nomad volume if it doesn't exist
Write-Host "💾 Setting up Nomad volume..." -ForegroundColor Yellow
try {
    nomad volume status carv-verifier-data 2>$null
    if ($LASTEXITCODE -ne 0) {
        Write-Host "📁 Creating Nomad volume..." -ForegroundColor Yellow
        Write-Host "⚠️  Please ensure the 'carv-verifier-data' volume exists in your Nomad cluster" -ForegroundColor Yellow
    }
} catch {
    Write-Host "⚠️  Please ensure the 'carv-verifier-data' volume exists in your Nomad cluster" -ForegroundColor Yellow
}

# Deploy to Nomad
Write-Host "🚀 Deploying to Nomad..." -ForegroundColor Yellow
nomad job run $NomadJobFile

if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Deployment successful!" -ForegroundColor Green
    Write-Host "📊 Check status with: nomad job status carv-verifier" -ForegroundColor Blue
    Write-Host "📋 View logs with: nomad logs -job carv-verifier" -ForegroundColor Blue
} else {
    Write-Host "❌ Deployment failed" -ForegroundColor Red
    exit 1
}

Write-Host "🎉 Carv Verifier Node deployment completed!" -ForegroundColor Green
