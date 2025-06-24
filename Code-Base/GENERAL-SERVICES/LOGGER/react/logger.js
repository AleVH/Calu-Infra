
const defaultMeta = {
    env: process.env.REACT_APP_ENV || 'dev',
    service: process.env.REACT_APP_SERVICE_NAME || 'frontend',
    version: process.env.REACT_APP_VERSION || '0.0.1'
};

function log ( level, message, extra = {} )
{
    const logEntry = {
        timestamp: new Date().toISOString(),
        level,
        message,
        ...defaultMeta,
        ...extra
    };

    if ( level === 'error' ) {
        console.error ( logEntry );
    } else if ( level === 'warn' ) {
        console.warn ( logEntry );
    } else {
        console.log ( logEntry );
    }

    // TODO: Forward logs to central logging API when ready
    // fetch('/api/logs', {
    //     method: 'POST',
    //     headers: { 'Content-Type': 'application/json' },
    //     body: JSON.stringify(logEntry)
    // });
}

export default {
    info: ( msg, extra ) => log ( 'info', msg, extra ),
    warn: ( msg, extra ) => log ( 'warn', msg, extra ),
    error: ( msg, extra ) => log ( 'error', msg, extra )
};
