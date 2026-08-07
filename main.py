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


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8080)