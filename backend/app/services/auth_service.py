from datetime import datetime, timezone
from flask_jwt_extended import create_access_token, create_refresh_token

from db.base import db
from db.models.user import User
from app.repositories import user_repository
from core.security import hash_password, verify_password

# Armazena refresh tokens revogados em memória.
# Simples para o MVP — será perdido ao reiniciar o servidor.
token_blocklist: set[str] = set()

def register(name: str, email: str, password: str) -> User:
    if user_repository.find_by_email(email):
        raise ValueError("email_already_registered")

    user = User(
        name=name,
        email=email,
        password_hash=hash_password(password)
    )
    return user_repository.save(user)

def login(email: str, password: str) -> dict:
    user = user_repository.find_by_email(email)

    if not user or not verify_password(password, user.password_hash):
        raise ValueError("invalid_credentials")

    access_token = create_access_token(identity=str(user.id))
    refresh_token = create_refresh_token(identity=str(user.id))

    return {"access_token": access_token, "refresh_token": refresh_token}

def refresh(identity: str) -> dict:
    access_token = create_access_token(identity=identity)
    return {"access_token": access_token}

def logout(jti: str) -> None:
    token_blocklist.add(jti)
