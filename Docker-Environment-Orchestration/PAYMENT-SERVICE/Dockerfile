# FastAPI Payment Service
FROM python:3.11-slim

# Set working directory
WORKDIR /app

# Copy the code from Code-Base
COPY . .

# Install dependencies if requirements.txt exists, otherwise install the basics
RUN if [ -f requirements.txt ]; then \
        pip install --no-cache-dir -r requirements.txt ; \
    else \
        pip install --no-cache-dir fastapi uvicorn ; \
    fi

# If no main.py exists, generate a dummy FastAPI app
RUN if [ ! -f main.py ]; then \
        echo "from fastapi import FastAPI\n\
\n\
app = FastAPI()\n\
\n\
@app.get('/')\n\
def read_root():\n\
    return { 'message': 'Payment service is running' }" > main.py ; \
    fi

EXPOSE 4004
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "4004"]
