import os

from flask import Flask
from flask_cors import CORS

app = Flask(__name__)
CORS(app)

@app.route("/")
def home():
    api_token = os.getenv("API_TOKEN")

    return {
        "message": "Hello from Python API 🚀",
        "app": os.getenv("APP_NAME"),
        "environment": os.getenv("ENVIRONMENT"),
        "secret_loaded": api_token is not None
    }

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8080)