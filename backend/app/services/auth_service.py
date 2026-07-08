from datetime import datetime, timezone
from flask_jwt_extended import create_access_token, create_refresh_token

from db.base import db
from db.models.user import User
from app.repositories import user_repository, revoked_token_repository
from core.security import hash_password, verify_password, is_password_strong

def register(name: str, email: str, username: str, password: str) -> User:
    if user_repository.find_by_email(email):
        raise ValueError("email_already_registered")

    if user_repository.find_by_username(username):
        raise ValueError("username_already_registered")

    if not is_password_strong(password):
        raise ValueError("weak_password")

    user = User(
        name=name,
        email=email,
        username=username,
        password_hash=hash_password(password)
    )
    return user_repository.save(user)

def login(identifier: str, password: str) -> dict:
    user = user_repository.find_by_username(identifier) or user_repository.find_by_email(identifier)

    if not user or not verify_password(password, user.password_hash):
        raise ValueError("invalid_credentials")

    access_token = create_access_token(identity=str(user.id))
    refresh_token = create_refresh_token(identity=str(user.id))

    return {"access_token": access_token, "refresh_token": refresh_token}

def get_current_user(user_id: int) -> User:
    user = user_repository.find_by_id(user_id)
    if not user:
        raise ValueError("user_not_found")
    return user

def refresh(identity: str) -> dict:
    access_token = create_access_token(identity=identity)
    return {"access_token": access_token}

def logout(jti: str) -> None:
    revoked_token_repository.add(jti)
