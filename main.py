import os

from flask import Flask
from flask_cors import CORS
from prometheus_flask_exporter import PrometheusMetrics

app = Flask(__name__)
CORS(app)
metrics = PrometheusMetrics(app, path="/metrics")


def get_counter_file():
    return os.getenv("COUNTER_FILE", "/data/counter.txt")


@app.route("/")
def home():
    api_token = os.getenv("API_TOKEN")

    return {
        "message": "Hello from Python API 🚀",
        "app": os.getenv("APP_NAME"),
        "environment": os.getenv("ENVIRONMENT"),
        "secret_loaded": api_token is not None,
    }


@app.route("/counter")
def counter():
    counter_file = get_counter_file()
    counter_dir = os.path.dirname(counter_file)

    os.makedirs(counter_dir, exist_ok=True)

    if not os.path.exists(counter_file):
        count = 0
    else:
        with open(counter_file, "r") as file:
            content = file.read().strip()
            count = int(content) if content else 0

    count += 1

    with open(counter_file, "w") as file:
        file.write(str(count))

    return {
        "message": "Persistent counter updated",
        "counter": count,
        "file": counter_file,
    }


# Liveness: solo confirma que el proceso responde. No comprueba dependencias:
# si fallara por una de ellas, Kubernetes reiniciaría pods que no pueden
# arreglarla y provocaría reinicios en cascada.
@app.route("/healthz")
@metrics.do_not_track()
def healthz():
    return {"status": "ok"}


# Readiness: comprueba lo que el pod necesita para atender tráfico. Si falla,
# Kubernetes deja de enviarle peticiones, pero no lo reinicia.
@app.route("/readyz")
@metrics.do_not_track()
def readyz():
    counter_dir = os.path.dirname(get_counter_file())

    if not os.access(counter_dir, os.W_OK):
        return {
            "status": "not ready",
            "reason": f"{counter_dir} no existe o no admite escritura",
        }, 503

    return {"status": "ready"}


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8080)