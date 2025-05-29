# RabbitMQ Worker (Python)
FROM python:3.11-slim

WORKDIR /app
COPY . .

# Install dependencies if available, otherwise install basic worker packages
RUN if [ -f requirements.txt ]; then \
        pip install --no-cache-dir -r requirements.txt ; \
    else \
        pip install --no-cache-dir pika ; \
    fi

# If no worker.py exists, generate a basic consumer
RUN if [ ! -f worker.py ]; then \
        echo "import pika\n\
\n\
def callback(ch, method, properties, body):\n\
    print(f'Received: {body}')\n\
\n\
connection = pika.BlockingConnection(pika.ConnectionParameters('rabbitmq'))\n\
channel = connection.channel()\n\
channel.queue_declare(queue='test')\n\
channel.basic_consume(queue='test', on_message_callback=callback, auto_ack=True)\n\
print('Waiting for messages. To exit press CTRL+C')\n\
channel.start_consuming()" > worker.py ; \
    fi

CMD [ "python", "worker.py" ]