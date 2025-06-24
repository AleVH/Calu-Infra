
import json
import logging
import os
from datetime import datetime

class JsonLogger:
    def __init__(self, service=None, env=None):
        self.service = service or os.getenv('SERVICE_NAME', 'unknown')
        self.env = env or os.getenv('ENV', 'dev')
        self.logger = logging.getLogger(self.service)
        self.logger.setLevel(logging.INFO)
        handler = logging.StreamHandler()
        handler.setFormatter(self.JsonFormatter())
        self.logger.addHandler(handler)

    class JsonFormatter(logging.Formatter):
        def format(self, record):
            log_record = {
                'timestamp': datetime.utcnow().isoformat() + 'Z',
                'level': record.levelname.lower(),
                'message': record.getMessage(),
                'service': record.name,
                'env': os.getenv('ENV', 'dev')
            }
            return json.dumps(log_record)

    def info(self, msg): self.logger.info(msg)
    def warn(self, msg): self.logger.warning(msg)
    def error(self, msg): self.logger.error(msg)
