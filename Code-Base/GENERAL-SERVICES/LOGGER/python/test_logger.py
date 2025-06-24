
from logger import JsonLogger

logger = JsonLogger(service='test-python')

logger.info('Logger test (info)')
logger.warn('Logger test (warn)')
logger.error('Logger test (error)')
