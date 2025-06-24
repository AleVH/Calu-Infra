
const fs = require('fs');
const path = require('path');

const CODE_BASE = path.resolve(__dirname, '../Code-Base');
const LOGGER_PATTERNS = {
    js: { logger: /logger\.(info|warn|error|debug)/, bad: /console\.log/ },
    py: { logger: /logger\.(info|warning|error|debug)/, bad: /print\(/ },
    java: { logger: /logger\.(info|warn|error|debug)/, bad: /System\.out\.println/ }
};

function detectLanguage ( folder )
{
    const files = fs.readdirSync ( folder );
    if ( files.some ( f => f.endsWith ( '.js' ) ) ) return 'js';
    if ( files.some ( f => f.endsWith ( '.py' ) ) ) return 'py';
    if ( files.some ( f => f.endsWith ( '.java' ) ) ) return 'java';
    return null;
}

function scanFolder ( folder, lang )
{
    const allFiles = fs.readdirSync ( folder );
    let hasLogger = false;
    let hasBad = false;

    allFiles.forEach ( file =>
    {
        const fullPath = path.join ( folder, file );
        if ( fs.statSync ( fullPath ).isFile () )
        {
            const content = fs.readFileSync ( fullPath, 'utf-8' );
            if ( LOGGER_PATTERNS[lang].logger.test ( content ) )
            {
                hasLogger = true;
            }
            if ( LOGGER_PATTERNS[lang].bad.test ( content ) )
            {
                hasBad = true;
            }
        }
    });

    return { hasLogger, hasBad };
}

function checkServices ()
{
    const folders = fs.readdirSync ( CODE_BASE );

    folders.forEach ( service =>
    {
        const servicePath = path.join ( CODE_BASE, service );
        if ( fs.statSync ( servicePath ).isDirectory () )
        {
            const lang = detectLanguage ( servicePath );
            if ( !lang )
            {
                console.log ( `🔍 ${service}: Unknown language or no source files` );
                return;
            }

            const { hasLogger, hasBad } = scanFolder ( servicePath, lang );
            if ( hasLogger )
            {
                console.log ( `✅ ${service}: Logger usage detected` );
            }
            else
            {
                console.log ( `⚠️  ${service}: No logger usage found` );
            }

            if ( hasBad )
            {
                console.log ( `🚫 ${service}: Detected bad logging practice (e.g. console.log)` );
            }
        }
    });
}

checkServices();
