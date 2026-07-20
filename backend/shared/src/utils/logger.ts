import winston from 'winston';

const { combine, timestamp, printf, colorize, json } = winston.format;

/**
 * JSON.stringify that tolerates circular references (e.g. an AxiosError's
 * `request`/`response` objects reference each other) by replacing repeat
 * occurrences with '[Circular]' instead of throwing.
 */
const safeStringify = (value: unknown): string => {
  const seen = new WeakSet<object>();
  return JSON.stringify(value, (_key, val) => {
    if (typeof val === 'object' && val !== null) {
      if (seen.has(val)) return '[Circular]';
      seen.add(val);
    }
    return val;
  });
};

// Custom format for development
const devFormat = printf(({ level, message, timestamp, ...metadata }) => {
  let msg = `${timestamp} [${level}]: ${message}`;
  if (Object.keys(metadata).length > 0) {
    msg += ` ${safeStringify(metadata)}`;
  }
  return msg;
});

// Create logger instance
const logger = winston.createLogger({
  level: process.env.LOG_LEVEL || 'info',
  format: combine(timestamp({ format: 'YYYY-MM-DD HH:mm:ss' }), json()),
  defaultMeta: { service: process.env.SERVICE_NAME || 'handy-go' },
  transports: [
    // Write all logs with importance level of 'error' or less to error.log
    new winston.transports.File({
      filename: 'logs/error.log',
      level: 'error',
      maxsize: 5242880, // 5MB
      maxFiles: 5,
    }),
    // Write all logs to combined.log
    new winston.transports.File({
      filename: 'logs/combined.log',
      maxsize: 5242880, // 5MB
      maxFiles: 5,
    }),
  ],
});

// If we're not in production, log to the console with colorized output
if (process.env.NODE_ENV !== 'production') {
  logger.add(
    new winston.transports.Console({
      format: combine(colorize({ all: true }), timestamp({ format: 'YYYY-MM-DD HH:mm:ss' }), devFormat),
    })
  );
}

// Stream for Morgan HTTP logging
export const morganStream = {
  write: (message: string) => {
    logger.http(message.trim());
  },
};

// Helper methods for structured logging
export const logInfo = (message: string, meta?: Record<string, unknown>) => {
  logger.info(message, meta);
};

export const logError = (message: string, error?: Error, meta?: Record<string, unknown>) => {
  logger.error(message, {
    ...meta,
    error: error
      ? {
          message: error.message,
          stack: error.stack,
          name: error.name,
        }
      : undefined,
  });
};

export const logWarn = (message: string, meta?: Record<string, unknown>) => {
  logger.warn(message, meta);
};

export const logDebug = (message: string, meta?: Record<string, unknown>) => {
  logger.debug(message, meta);
};

export const logHttp = (message: string, meta?: Record<string, unknown>) => {
  logger.http(message, meta);
};

export default logger;
