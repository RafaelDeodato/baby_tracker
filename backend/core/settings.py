import os
from datetime import timedelta
from dotenv import load_dotenv

load_dotenv()

class Config:
    SECRET_KEY = os.getenv("SECRET_KEY")
    JWT_SECRET_KEY = os.getenv("JWT_SECRET_KEY")
    SQLALCHEMY_DATABASE_URI = os.getenv("DATABASE_URL")
    SQLALCHEMY_TRACK_MODIFICATIONS = False
    DEBUG = os.getenv("FLASK_DEBUG", "false").lower() == "true"

    # Explícitos em vez de depender do default da lib (15min / 30 dias) —
    # deixa a política de sessão visível no código e ajustável via .env
    # (útil, por exemplo, pra forçar expiração rápida em teste manual).
    JWT_ACCESS_TOKEN_EXPIRES = timedelta(
        seconds=int(os.getenv("JWT_ACCESS_TOKEN_EXPIRES_SECONDS", 900))
    )
    JWT_REFRESH_TOKEN_EXPIRES = timedelta(
        seconds=int(os.getenv("JWT_REFRESH_TOKEN_EXPIRES_SECONDS", 60 * 60 * 24 * 30))
    )

    # Vazio por padrão — nega CORS pra qualquer origem de navegador até que
    # um cliente web real exista (o app mobile não é afetado por CORS, só
    # requisições feitas a partir de um navegador). Configurar via variável
    # de ambiente (separado por vírgula) quando esse cliente existir.
    CORS_ALLOWED_ORIGINS = [
        origin.strip() for origin in os.getenv("CORS_ALLOWED_ORIGINS", "").split(",") if origin.strip()
    ]
