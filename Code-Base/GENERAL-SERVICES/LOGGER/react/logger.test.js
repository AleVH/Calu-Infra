
import logger from './logger';

logger.info ( 'Logger test (info)', { userId: 123 } );
logger.warn ( 'Logger test (warn)', { route: '/dashboard' } );
logger.error ( 'Logger test (error)', { component: 'Header' } );
