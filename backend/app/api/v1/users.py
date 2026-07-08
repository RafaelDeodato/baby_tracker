from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required

from app.repositories import user_repository

users_bp = Blueprint("users", __name__)

@users_bp.get("/search")
@jwt_required()
def search_users():
    username = request.args.get("username", "")
    user = user_repository.find_by_username(username)
    if not user:
        return jsonify({"error": "user_not_found", "message": "Usuário não encontrado."}), 404
    return jsonify({"id": user.id, "name": user.name, "username": user.username}), 200
