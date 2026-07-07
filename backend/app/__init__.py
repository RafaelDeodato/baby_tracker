from flask import Flask, jsonify
from flask_jwt_extended import JWTManager
from flask_cors import CORS
from core.settings import Config
from core.limiter import limiter
from db.base import db
from app.api.v1 import v1_bp
from app.repositories import revoked_token_repository

def create_app():
    app = Flask(__name__)
    app.config.from_object(Config)

    CORS(app, origins=Config.CORS_ALLOWED_ORIGINS)
    db.init_app(app)
    jwt = JWTManager(app)
    limiter.init_app(app)

    @jwt.token_in_blocklist_loader
    def check_if_token_revoked(jwt_header, jwt_payload):
        return revoked_token_repository.is_revoked(jwt_payload["jti"])

    # Flask-Limiter devolve HTML por padrão no 429 — quebra o contrato de
    # sempre responder JSON (error/message) que o resto da API segue.
    @app.errorhandler(429)
    def ratelimit_handler(e):
        return jsonify({
            "error": "rate_limit_exceeded",
            "message": "Muitas tentativas. Aguarde um minuto e tente novamente."
        }), 429

    app.register_blueprint(v1_bp, url_prefix="/api/v1")

    @app.route("/health")
    def health():
        return {"status": "ok"}

    return app
