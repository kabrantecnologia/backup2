/**
 * Sistema de Logging Estruturado
 * 
 * Fornece logging consistente e estruturado para as Edge Functions,
 * com suporte a diferentes níveis de log e formatação JSON.
 */

// Declaração para o ambiente Deno
declare const Deno: any;

/**
 * Níveis de log disponíveis
 */
export enum LogLevel {
  DEBUG = 0,
  INFO = 1,
  WARN = 2,
  ERROR = 3,
  CRITICAL = 4
}

/**
 * Interface para configuração do logger
 */
export interface LoggerConfig {
  name: string;
  minLevel?: LogLevel;
  includeTimestamp?: boolean;
  includeLevel?: boolean;
}

/**
 * Interface para entrada de log
 */
export interface LogEntry {
  timestamp: string;
  level: string;
  logger: string;
  message: string;
  data?: any;
  error?: {
    message: string;
    stack?: string;
  };
}

/**
 * Classe Logger para logging estruturado
 */
export class Logger {
  private name: string;
  private minLevel: LogLevel;
  private includeTimestamp: boolean;
  private includeLevel: boolean;

  constructor(config: LoggerConfig) {
    this.name = config.name;
    this.minLevel = config.minLevel ?? LogLevel.INFO;
    this.includeTimestamp = config.includeTimestamp ?? true;
    this.includeLevel = config.includeLevel ?? true;
  }

  /**
   * Log de debug (desenvolvimento)
   */
  debug(message: string, data?: any): void {
    this.log(LogLevel.DEBUG, message, data);
  }

  /**
   * Log informativo
   */
  info(message: string, data?: any): void {
    this.log(LogLevel.INFO, message, data);
  }

  /**
   * Log de aviso
   */
  warn(message: string, data?: any): void {
    this.log(LogLevel.WARN, message, data);
  }

  /**
   * Log de erro
   */
  error(message: string, data?: any): void {
    this.log(LogLevel.ERROR, message, data);
  }

  /**
   * Log crítico
   */
  critical(message: string, data?: any): void {
    this.log(LogLevel.CRITICAL, message, data);
  }

  /**
   * Método interno para realizar o log
   */
  private log(level: LogLevel, message: string, data?: any): void {
    // Verifica se deve logar baseado no nível mínimo
    if (level < this.minLevel) {
      return;
    }

    // Constrói a entrada de log
    const entry: LogEntry = {
      timestamp: new Date().toISOString(),
      level: LogLevel[level],
      logger: this.name,
      message
    };

    // Adiciona dados se fornecidos
    if (data !== undefined) {
      // Se é um Error, extrai message e stack
      if (data instanceof Error) {
        entry.error = {
          message: data.message,
          stack: data.stack
        };
      } else {
        entry.data = data;
      }
    }

    // Formata e emite o log
    this.emit(entry);
  }

  /**
   * Emite o log formatado com cores e formatação legível
   */
  private emit(entry: LogEntry): void {
    try {
      // Cores ANSI para terminal
      const colors = {
        DEBUG: '\x1b[36m',    // Cyan
        INFO: '\x1b[32m',     // Green
        WARN: '\x1b[33m',     // Yellow
        ERROR: '\x1b[31m',    // Red
        CRITICAL: '\x1b[35m', // Magenta
        RESET: '\x1b[0m',     // Reset
        DIM: '\x1b[2m',       // Dim
        BOLD: '\x1b[1m'       // Bold
      };

      const color = colors[entry.level as keyof typeof colors] || colors.RESET;
      const timestamp = new Date(entry.timestamp).toLocaleTimeString('pt-BR');
      
      // Formato legível: [HH:MM:SS] LEVEL [logger] message
      let formatted = `${colors.DIM}[${timestamp}]${colors.RESET} ${color}${colors.BOLD}${entry.level.padEnd(8)}${colors.RESET} ${colors.DIM}[${entry.logger}]${colors.RESET} ${entry.message}`;

      // Adiciona dados/erros se houver
      if (entry.data) {
        const dataStr = JSON.stringify(entry.data, null, 2);
        formatted += `\n${colors.DIM}  📊 Dados:${colors.RESET}\n${colors.DIM}${dataStr}${colors.RESET}`;
      }
      
      if (entry.error) {
        formatted += `\n${colors.ERROR}  ❌ Erro: ${entry.error.message}${colors.RESET}`;
        if (entry.error.stack) {
          formatted += `\n${colors.DIM}  📍 Stack:${colors.RESET}\n${colors.DIM}${entry.error.stack}${colors.RESET}`;
        }
      }

      console.log(formatted);
    } catch (error) {
      // Fallback simples se formatação falhar
      console.log(`[${entry.level}] ${entry.logger}: ${entry.message}`);
    }
  }
}

/**
 * Factory function para criar loggers
 */
export function createLogger(config: LoggerConfig): Logger {
  return new Logger(config);
}

/**
 * Logger padrão para uso rápido
 */
export const defaultLogger = createLogger({
  name: 'EdgeFunction',
  minLevel: LogLevel.INFO
});

/**
 * Utilitário para logar erros de forma consistente
 */
export function logError(logger: Logger, error: Error, context?: string): void {
  logger.error(context || 'Erro não tratado', {
    message: error.message,
    stack: error.stack,
    name: error.name
  });
}

/**
 * Utilitário para logar performance
 */
export function logPerformance(logger: Logger, operation: string, startTime: number): void {
  const duration = Date.now() - startTime;
  logger.info(`Performance: ${operation}`, { duration_ms: duration });
}
