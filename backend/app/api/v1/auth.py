from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required, get_jwt, get_jwt_identity

from app.services import auth_service
from core.limiter import limiter

auth_bp = Blueprint("auth", __name__)

@auth_bp.post("/register")
@limiter.limit("5 per minute")
def register():
    data = request.get_json()
    try:
        user = auth_service.register(
            name=data["name"],
            email=data["email"],
            username=data["username"],
            password=data["password"]
        )
        return jsonify({"id": user.id, "name": user.name, "email": user.email, "username": user.username}), 201
    except ValueError as e:
        error = str(e)
        if error == "email_already_registered":
            return jsonify({"error": error, "message": "E-mail já cadastrado."}), 409
        if error == "username_already_registered":
            return jsonify({"error": error, "message": "Nome de usuário já cadastrado."}), 409
        if error == "weak_password":
            return jsonify({
                "error": error,
                "message": "A senha precisa ter no mínimo 8 caracteres, com ao menos uma letra e um número."
            }), 422

@auth_bp.post("/login")
@limiter.limit("5 per minute")
def login():
    data = request.get_json()
    try:
        tokens = auth_service.login(
            identifier=data["identifier"],
            password=data["password"]
        )
        return jsonify(tokens), 200
    except ValueError:
        return jsonify({"error": "invalid_credentials", "message": "Usuário/e-mail ou senha inválidos."}), 401

@auth_bp.get("/me")
@jwt_required()
def me():
    user_id = int(get_jwt_identity())
    user = auth_service.get_current_user(user_id)
    return jsonify({"id": user.id, "name": user.name, "email": user.email, "username": user.username}), 200

@auth_bp.post("/refresh")
@jwt_required(refresh=True)
def refresh():
    identity = get_jwt_identity()
    tokens = auth_service.refresh(identity)
    return jsonify(tokens), 200

@auth_bp.post("/logout")
@jwt_required(refresh=True)
def logout():
    jti = get_jwt()["jti"]
    auth_service.logout(jti)
    return jsonify({"message": "Logout realizado com sucesso."}), 200
