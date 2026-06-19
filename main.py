import os

from flask import Flask
from flask_cors import CORS

app = Flask(__name__)
CORS(app)

COUNTER_FILE = "/data/counter.txt"


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
    os.makedirs("/data", exist_ok=True)

    if not os.path.exists(COUNTER_FILE):
        count = 0
    else:
        with open(COUNTER_FILE, "r") as file:
            content = file.read().strip()
            count = int(content) if content else 0

    count += 1

    with open(COUNTER_FILE, "w") as file:
        file.write(str(count))

    return {
        "message": "Persistent counter updated",
        "counter": count,
        "file": COUNTER_FILE,
    }


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8080)