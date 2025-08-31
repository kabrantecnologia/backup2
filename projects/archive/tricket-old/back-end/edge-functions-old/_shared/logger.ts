// Utilitário para logging nas Edge Functions
// Este arquivo fornece funções para registrar logs tanto no console quanto em arquivos

declare const Deno: any;

// Níveis de log
export enum LogLevel {
  DEBUG = 'DEBUG',
  INFO = 'INFO',
  WARN = 'WARN',
  ERROR = 'ERROR',
  CRITICAL = 'CRITICAL'
}

// Configuração do logger
interface LoggerConfig {
  // Nome do componente/função
  name: string;
  // Diretório para os arquivos de log (opcional, apenas para desenvolvimento local)
  logDir?: string;
  // Se deve gravar em arquivo
  writeToFile?: boolean;
  // Nível mínimo de log
  minLevel?: LogLevel;
}

/**
 * Classe Logger para padronizar a saída de logs
 */
export class Logger {
  private name: string;
  private logDir: string;
  private writeToFile: boolean;
  private minLevel: LogLevel;
  private logFileName: string;
  private isRunningLocally: boolean;

  constructor(config: LoggerConfig) {
    this.name = config.name;
    this.logDir = config.logDir || './logs';
    this.writeToFile = config.writeToFile ?? true;
    this.minLevel = config.minLevel || LogLevel.DEBUG;
    this.logFileName = `${this.name.toLowerCase().replace(/[^a-z0-9]/g, '_')}.log`;
    
    // Verifica se está rodando localmente ou no ambiente Supabase Edge Functions
    this.isRunningLocally = this.checkIfRunningLocally();
    
    // Cria o diretório de logs se estiver rodando localmente
    if (this.isRunningLocally && this.writeToFile) {
      this.ensureLogDir();
    }
  }

  /**
   * Verifica se a função está rodando localmente ou no Supabase Edge Functions
   */
  private checkIfRunningLocally(): boolean {
    try {
      // No ambiente Edge Functions, algumas operações de IO não são permitidas
      // Esta é uma heurística simples para detectar o ambiente local
      return typeof Deno !== 'undefined' && 
             typeof Deno.env !== 'undefined' && 
             Deno.env.get('SUPABASE_URL') === undefined;
    } catch (error) {
      return false;
    }
  }

  /**
   * Garante que o diretório de logs exista
   */
  private async ensureLogDir() {
    try {
      // Verifica se o diretório existe
      const dirExists = await Deno.stat(this.logDir).catch(() => false);
      
      // Se não existir, cria
      if (!dirExists) {
        await Deno.mkdir(this.logDir, { recursive: true });
      }
    } catch (error) {
      console.error(`Não foi possível criar o diretório de logs: ${error.message}`);
      this.writeToFile = false;
    }
  }

  /**
   * Formata a mensagem de log
   */
  private formatLogMessage(level: LogLevel, message: string, data?: any): string {
    const timestamp = new Date().toISOString();
    const dataStr = data ? ` | ${JSON.stringify(data)}` : '';
    return `[${timestamp}] [${level}] [${this.name}] ${message}${dataStr}`;
  }

  /**
   * Escreve no arquivo de log (apenas em desenvolvimento local)
   */
  private async writeToLogFile(message: string) {
    if (!this.isRunningLocally || !this.writeToFile) return;
    
    try {
      const logPath = `${this.logDir}/${this.logFileName}`;
      const encoder = new TextEncoder();
      const data = encoder.encode(message + '\n');
      
      // Abre o arquivo em modo append (ou cria se não existir)
      const file = await Deno.open(logPath, { write: true, create: true, append: true });
      await Deno.write(file.rid, data);
      Deno.close(file.rid);
    } catch (error) {
      console.error(`Não foi possível escrever no arquivo de log: ${error.message}`);
    }
  }

  /**
   * Determina se um nível de log deve ser registrado
   */
  private shouldLog(level: LogLevel): boolean {
    const levels = Object.values(LogLevel);
    return levels.indexOf(level) >= levels.indexOf(this.minLevel);
  }

  /**
   * Registra uma mensagem de log
   */
  private async log(level: LogLevel, message: string, data?: any) {
    if (!this.shouldLog(level)) return;
    
    const formattedMessage = this.formatLogMessage(level, message, data);
    
    // Sempre loga no console
    if (level === LogLevel.ERROR || level === LogLevel.CRITICAL) {
      console.error(formattedMessage);
    } else if (level === LogLevel.WARN) {
      console.warn(formattedMessage);
    } else {
      console.log(formattedMessage);
    }
    
    // Se configurado, tenta escrever no arquivo
    if (this.writeToFile) {
      await this.writeToLogFile(formattedMessage);
    }
  }

  /**
   * Logs a debug message
   */
  debug(message: string, data?: any) {
    this.log(LogLevel.DEBUG, message, data);
  }

  /**
   * Logs an info message
   */
  info(message: string, data?: any) {
    this.log(LogLevel.INFO, message, data);
  }

  /**
   * Logs a warning message
   */
  warn(message: string, data?: any) {
    this.log(LogLevel.WARN, message, data);
  }

  /**
   * Logs an error message
   */
  error(message: string, data?: any) {
    this.log(LogLevel.ERROR, message, data);
  }

  /**
   * Logs a critical message
   */
  critical(message: string, data?: any) {
    this.log(LogLevel.CRITICAL, message, data);
  }
}

/**
 * Cria uma instância do logger
 */
export function createLogger(config: LoggerConfig): Logger {
  return new Logger(config);
}
