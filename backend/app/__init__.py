from flask import Flask
from flask_jwt_extended import JWTManager
from core.settings import Config
from db.base import db

def create_app():
    app = Flask(__name__)
    app.config.from_object(Config)

    db.init_app(app)
    JWTManager(app)

    @app.route("/health")
    def health():
        return {"status": "ok"}

    return app
