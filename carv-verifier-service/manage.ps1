# Carv Verifier Node Management Script (PowerShell)
# This script provides commands to manage the Carv verifier node

param(
    [Parameter(Position=0)]
    [string]$Command,
    
    [Parameter(Position=1)]
    [string]$Parameter
)

# Configuration
$JobName = "carv-verifier"
$ServiceName = "carv-verifier-service"

# Function to display usage
function Show-Usage {
    Write-Host "Carv Verifier Node Management Script" -ForegroundColor Blue
    Write-Host ""
    Write-Host "Usage: .\manage.ps1 [COMMAND] [PARAMETER]"
    Write-Host ""
    Write-Host "Commands:"
    Write-Host "  status      - Show job status"
    Write-Host "  logs        - View job logs"
    Write-Host "  restart     - Restart the job"
    Write-Host "  stop        - Stop the job"
    Write-Host "  start       - Start the job"
    Write-Host "  scale N     - Scale to N instances"
    Write-Host "  health      - Check service health"
    Write-Host "  validate    - Validate service configuration"
    Write-Host "  build       - Build Docker image"
    Write-Host "  deploy      - Deploy to Nomad"
    Write-Host "  help        - Show this help message"
    Write-Host ""
}

# Function to show job status
function Show-Status {
    Write-Host "📊 Job Status:" -ForegroundColor Blue
    nomad job status $JobName
    Write-Host ""
    Write-Host "📋 Allocation Status:" -ForegroundColor Blue
    nomad job allocs $JobName
}

# Function to view logs
function View-Logs {
    Write-Host "📋 Viewing logs for job: $JobName" -ForegroundColor Blue
    nomad logs -job $JobName
}

# Function to restart job
function Restart-Job {
    Write-Host "🔄 Restarting job: $JobName" -ForegroundColor Yellow
    nomad job restart $JobName
    Write-Host "✅ Job restart initiated" -ForegroundColor Green
}

# Function to stop job
function Stop-Job {
    Write-Host "⏹️  Stopping job: $JobName" -ForegroundColor Yellow
    nomad job stop $JobName
    Write-Host "✅ Job stopped" -ForegroundColor Green
}

# Function to start job
function Start-Job {
    Write-Host "▶️  Starting job: $JobName" -ForegroundColor Yellow
    nomad job run carv-verifier.nomad
    Write-Host "✅ Job started" -ForegroundColor Green
}

# Function to scale job
function Scale-Job {
    param([string]$Count)
    
    if ([string]::IsNullOrEmpty($Count)) {
        Write-Host "❌ Please specify the number of instances" -ForegroundColor Red
        Write-Host "Usage: .\manage.ps1 scale <number>"
        exit 1
    }
    
    Write-Host "📈 Scaling job to $Count instances" -ForegroundColor Yellow
    nomad job scale $JobName $Count
    Write-Host "✅ Job scaled to $Count instances" -ForegroundColor Green
}

# Function to check health
function Check-Health {
    Write-Host "🏥 Checking service health..." -ForegroundColor Blue
    
    # Check if job is running
    $jobStatus = nomad job status $JobName 2>$null
    if ($jobStatus -match "running") {
        Write-Host "✅ Job is running" -ForegroundColor Green
    } else {
        Write-Host "❌ Job is not running" -ForegroundColor Red
        return 1
    }
    
    # Check allocations
    $allocs = nomad job allocs $JobName 2>$null | Select-String "running"
    if ($allocs) {
        $allocCount = ($allocs | Measure-Object).Count
        Write-Host "✅ $allocCount allocation(s) running" -ForegroundColor Green
    } else {
        Write-Host "❌ No running allocations" -ForegroundColor Red
        return 1
    }
    
    Write-Host "✅ Service is healthy" -ForegroundColor Green
}

# Function to validate service
function Validate-Service {
    Write-Host "🔍 Validating service configuration..." -ForegroundColor Yellow
    npm run validate
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Service validation passed" -ForegroundColor Green
    } else {
        Write-Host "❌ Service validation failed" -ForegroundColor Red
        exit 1
    }
}

# Function to build Docker image
function Build-Image {
    Write-Host "🔨 Building Docker image..." -ForegroundColor Yellow
    npm run build:docker
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Docker image built successfully" -ForegroundColor Green
    } else {
        Write-Host "❌ Docker build failed" -ForegroundColor Red
        exit 1
    }
}

# Function to deploy
function Deploy {
    Write-Host "🚀 Deploying to Nomad..." -ForegroundColor Yellow
    .\deploy.ps1
}

# Main script logic
switch ($Command.ToLower()) {
    "status" {
        Show-Status
    }
    "logs" {
        View-Logs
    }
    "restart" {
        Restart-Job
    }
    "stop" {
        Stop-Job
    }
    "start" {
        Start-Job
    }
    "scale" {
        Scale-Job $Parameter
    }
    "health" {
        Check-Health
    }
    "validate" {
        Validate-Service
    }
    "build" {
        Build-Image
    }
    "deploy" {
        Deploy
    }
    "help" {
        Show-Usage
    }
    default {
        if ([string]::IsNullOrEmpty($Command)) {
            Show-Usage
        } else {
            Write-Host "❌ Unknown command: $Command" -ForegroundColor Red
            Write-Host ""
            Show-Usage
            exit 1
        }
    }
}
