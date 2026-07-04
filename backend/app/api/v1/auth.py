from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required, get_jwt, get_jwt_identity

from app.services import auth_service

auth_bp = Blueprint("auth", __name__)

@auth_bp.post("/register")
def register():
    data = request.get_json()
    try:
        user = auth_service.register(
            name=data["name"],
            email=data["email"],
            password=data["password"]
        )
        return jsonify({"id": user.id, "name": user.name, "email": user.email}), 201
    except ValueError as e:
        return jsonify({"error": str(e), "message": "E-mail já cadastrado."}), 409

@auth_bp.post("/login")
def login():
    data = request.get_json()
    try:
        tokens = auth_service.login(
            email=data["email"],
            password=data["password"]
        )
        return jsonify(tokens), 200
    except ValueError:
        return jsonify({"error": "invalid_credentials", "message": "E-mail ou senha inválidos."}), 401

@auth_bp.get("/me")
@jwt_required()
def me():
    user_id = int(get_jwt_identity())
    user = auth_service.get_current_user(user_id)
    return jsonify({"id": user.id, "name": user.name, "email": user.email}), 200

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
