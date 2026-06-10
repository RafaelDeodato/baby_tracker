from flask import Flask
from flask_jwt_extended import JWTManager
from core.settings import Config
from db.base import db
from app.api.v1 import v1_bp
from app.services.auth_service import token_blocklist

def create_app():
    app = Flask(__name__)
    app.config.from_object(Config)

    db.init_app(app)
    jwt = JWTManager(app)

    @jwt.token_in_blocklist_loader
    def check_if_token_revoked(jwt_header, jwt_payload):
        return jwt_payload["jti"] in token_blocklist

    app.register_blueprint(v1_bp, url_prefix="/api/v1")

    @app.route("/health")
    def health():
        return {"status": "ok"}

    return app
