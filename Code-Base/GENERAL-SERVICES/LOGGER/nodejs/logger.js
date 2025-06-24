
const { createLogger, format, transports } = require('winston');

// Create a Winston logger with JSON formatting
const logger = createLogger({
    level: process.env.LOG_LEVEL || 'info',
    format: format.combine(
        format.timestamp(),
        format.json()
    ),
    defaultMeta: {
        service: process.env.SERVICE_NAME || 'unknown',
        env: process.env.NODE_ENV || 'dev'
    },
    transports: [ new transports.Console() ]
});

module.exports = logger;
