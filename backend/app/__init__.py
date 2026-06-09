from flask import Flask
from flask_jwt_extended import JWTManager
from core.settings import Config

def create_app():
    app = Flask(__name__)
    app.config.from_object(Config)

    JWTManager(app)

    @app.route("/health")
    def health():
        return {"status": "ok"}

    return app
