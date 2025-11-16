FROM python:3.11-slim

WORKDIR /app

# Install Flask
COPY requirements.txt /app/
RUN pip install --no-cache-dir -r requirements.txt

# Copy the webhook server script
COPY server.py /app/

# Make it executable
RUN chmod +x /app/server.py

# Run as non-root user
RUN useradd -m -u 1000 webhook && chown -R webhook:webhook /app
USER webhook

# Expose the webhook port
EXPOSE 8443

# Run the server
CMD ["python3", "/app/server.py"]