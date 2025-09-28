import type { HookContext } from '@deeep-network/riptide'
import { spawn, ChildProcess } from 'child_process'
import { promises as fs } from 'fs'
import path from 'path'

let verifierProcess: ChildProcess | null = null

module.exports = {
  installSecrets: async ({ logger, secrets }: HookContext) => {
    logger.info('Installing secrets for Carv verifier node')
    
    try {
      // Validate required secrets
      if (!secrets.CARV_PRIVATE_KEY) {
        throw new Error('CARV_PRIVATE_KEY is required but not provided')
      }

      // Update config file with environment variables
      const configPath = '/data/conf/config_docker.yaml'
      let configContent = await fs.readFile(configPath, 'utf-8')
      
      // Replace environment variable placeholders
      configContent = configContent.replace(
        '${CARV_PRIVATE_KEY}',
        secrets.CARV_PRIVATE_KEY
      )
      
      if (secrets.CARV_REWARD_CLAIMER_ADDR) {
        configContent = configContent.replace(
          '${CARV_REWARD_CLAIMER_ADDR:-0x0000000000000000000000000000000000000000}',
          secrets.CARV_REWARD_CLAIMER_ADDR
        )
      }
      
      await fs.writeFile(configPath, configContent)
      logger.info('Configuration file updated with secrets')
      
      return { success: true }
    } catch (error) {
      logger.error('Failed to install secrets:', String(error))
      throw error
    }
  },

  start: async ({ logger }: HookContext) => {
    logger.info('Starting Carv verifier node')
    
    try {
      // Start the Carv verifier node process
      verifierProcess = spawn('carv-verifier', [
        '--config', '/data/conf/config_docker.yaml',
        '--data-dir', '/data',
        '--log-level', 'info'
      ], {
        stdio: ['ignore', 'pipe', 'pipe'],
        cwd: '/data'
      })

      // Handle process output
      verifierProcess.stdout?.on('data', (data) => {
        logger.info(`Verifier: ${data.toString().trim()}`)
      })

      verifierProcess.stderr?.on('data', (data) => {
        logger.error(`Verifier Error: ${data.toString().trim()}`)
      })

      verifierProcess.on('error', (error) => {
        logger.error('Failed to start verifier process:', String(error))
        throw error
      })

      verifierProcess.on('exit', (code, signal) => {
        if (code !== 0) {
          logger.error(`Verifier process exited with code ${code} and signal ${signal}`)
        } else {
          logger.info('Verifier process exited normally')
        }
      })

      // Wait a moment to ensure the process started
      await new Promise(resolve => setTimeout(resolve, 2000))
      
      if (verifierProcess.killed) {
        throw new Error('Verifier process failed to start')
      }

      logger.info('Carv verifier node started successfully')
    } catch (error) {
      logger.error('Failed to start Carv verifier node:', String(error))
      throw error
    }
  },

  health: async ({ logger }: HookContext) => {
    logger.debug('Performing health check on Carv verifier node')
    
    try {
      // Check if the verifier process is still running
      if (!verifierProcess || verifierProcess.killed) {
        logger.warn('Verifier process is not running')
        return false
      }

      // Check if the verifier is responding (you might want to add actual health check logic here)
      // For now, we'll just check if the process is alive
      const isAlive = verifierProcess.exitCode === null
      
      if (isAlive) {
        logger.debug('Verifier node is healthy')
        return true
      } else {
        logger.warn('Verifier node is not responding')
        return false
      }
    } catch (error) {
      logger.error('Health check failed:', String(error))
      return false
    }
  },

  stop: async ({ logger }: HookContext) => {
    logger.info('Stopping Carv verifier node')
    
    try {
      if (verifierProcess && !verifierProcess.killed) {
        // Send SIGTERM first
        verifierProcess.kill('SIGTERM')
        
        // Wait for graceful shutdown
        await new Promise((resolve) => {
          const timeout = setTimeout(() => {
            logger.warn('Graceful shutdown timeout, forcing kill')
            verifierProcess?.kill('SIGKILL')
            resolve(void 0)
          }, 30000) // 30 second timeout
          
          verifierProcess?.on('exit', () => {
            clearTimeout(timeout)
            resolve(void 0)
          })
        })
      }
      
      verifierProcess = null
      logger.info('Carv verifier node stopped successfully')
    } catch (error) {
      logger.error('Error stopping Carv verifier node:', String(error))
      throw error
    }
  }
}
