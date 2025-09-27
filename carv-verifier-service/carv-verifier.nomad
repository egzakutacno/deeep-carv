job "carv-verifier" {
  datacenters = ["dc1"]
  type = "service"
  
  # Update strategy for rolling updates
  update {
    max_parallel = 1
    health_check = "checks"
    min_healthy_time = "30s"
    healthy_deadline = "5m"
    auto_revert = true
    canary = 0
  }

  # Restart policy
  reschedule {
    attempts = 3
    interval = "5m"
    delay = "30s"
    delay_function = "constant"
    max_delay = "1h"
    unlimited = false
  }

  group "verifier" {
    count = 1

    # Network configuration
    network {
      mode = "bridge"
      port "http" {
        static = 8545
        to = 8545
      }
      port "metrics" {
        static = 9090
        to = 9090
      }
    }

    # Volume mounts for persistent data
    volume "carv-data" {
      type = "host"
      read_only = false
      source = "carv-verifier-data"
    }

    task "verifier" {
      driver = "docker"

      # Resource allocation
      resources {
        cpu = 1000    # 1 CPU core
        memory = 2048 # 2GB RAM
        disk = 10240  # 10GB disk space
      }

      # Docker configuration
      config {
        image = "reef-carv-verifier-service:latest"
        ports = ["http", "metrics"]
        
        # Volume mounts
        volumes = [
          "/data/conf:/data/conf:rw",
          "/data/keystore:/data/keystore:rw", 
          "/data/logs:/data/logs:rw"
        ]
        
        # Environment variables
        env = {
          CARV_NETWORK = "mainnet"
          CARV_RPC_URL = "https://mainnet.carv.io"
          NODE_ENV = "production"
        }
      }

      # Service discovery
      service {
        name = "carv-verifier"
        tags = ["carv", "verifier", "blockchain"]
        port = "http"
        
        check {
          name = "carv-verifier-health"
          type = "http"
          path = "/health"
          interval = "30s"
          timeout = "10s"
          failures_before_critical = 3
        }
        
        check {
          name = "carv-verifier-tcp"
          type = "tcp"
          interval = "30s"
          timeout = "5s"
          failures_before_critical = 3
        }
      }

      # Health checks
      check {
        name = "carv-verifier-process"
        type = "script"
        command = "/usr/local/bin/riptide"
        args = ["health"]
        interval = "30s"
        timeout = "10s"
        failures_before_critical = 3
      }

      # Volume mounts
      volume_mount {
        volume = "carv-data"
        destination = "/data"
        read_only = false
      }

      # Restart policy
      restart {
        attempts = 3
        interval = "5m"
        delay = "30s"
        mode = "fail"
      }

      # Logging configuration
      logging {
        type = "docker"
        config {
          max-file = "10"
          max-size = "10m"
        }
      }
    }
  }

  # Scaling configuration
  scaling {
    enabled = false
    min = 1
    max = 5
  }
}
