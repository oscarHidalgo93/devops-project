FROM python:3.11-slim

#No escbribir buffer interno de python y salir por la stdout.
ENV PYTHONDONTWRITEBYTECODE=1 
ENV PYTHONUNBUFFERED=1

WORKDIR /app

COPY requirements.txt .
RUN pip install --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt &&\
    pip uninstall -y pip setuptools wheel

COPY main.py .

EXPOSE 8080

CMD ["python", "main.py