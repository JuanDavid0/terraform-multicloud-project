FROM python:3.9-slim
WORKDIR /app

# Copiamos requirements e instalamos
COPY requirements.txt /app/
RUN pip install --no-cache-dir -r requirements.txt

# Copiamos la app
COPY microservice_app.py /app/

EXPOSE 80
CMD ["python", "microservice_app.py"]