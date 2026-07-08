from datetime import date
from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity

from app.services import baby_service

babies_bp = Blueprint("babies", __name__)

def _serialize(baby):
    return {
        "id": baby.id,
        "name": baby.name,
        "birth_date": baby.birth_date.isoformat(),
        "created_at": baby.created_at.isoformat()
    }

@babies_bp.get("/")
@jwt_required()
def list_babies():
    user_id = int(get_jwt_identity())
    babies = baby_service.list_babies(user_id)
    return jsonify([_serialize(b) for b in babies]), 200

@babies_bp.post("/")
@jwt_required()
def create_baby():
    user_id = int(get_jwt_identity())
    data = request.get_json()
    baby = baby_service.create_baby(
        user_id=user_id,
        name=data["name"],
        birth_date=date.fromisoformat(data["birth_date"])
    )
    return jsonify(_serialize(baby)), 201

@babies_bp.get("/<int:baby_id>")
@jwt_required()
def get_baby(baby_id):
    user_id = int(get_jwt_identity())
    try:
        baby = baby_service.get_baby(baby_id, user_id)
        return jsonify(_serialize(baby)), 200
    except ValueError:
        return jsonify({"error": "baby_not_found", "message": "Bebê não encontrado."}), 404

@babies_bp.put("/<int:baby_id>")
@jwt_required()
def update_baby(baby_id):
    user_id = int(get_jwt_identity())
    data = request.get_json()
    try:
        baby = baby_service.update_baby(
            baby_id=baby_id,
            user_id=user_id,
            name=data["name"],
            birth_date=date.fromisoformat(data["birth_date"])
        )
        return jsonify(_serialize(baby)), 200
    except ValueError as e:
        if str(e) == "forbidden":
            return jsonify({"error": "forbidden", "message": "Você não tem permissão pra editar este bebê."}), 403
        return jsonify({"error": "baby_not_found", "message": "Bebê não encontrado."}), 404

@babies_bp.delete("/<int:baby_id>")
@jwt_required()
def delete_baby(baby_id):
    user_id = int(get_jwt_identity())
    try:
        baby_service.delete_baby(baby_id, user_id)
        return "", 204
    except ValueError as e:
        if str(e) == "forbidden":
            return jsonify({"error": "forbidden", "message": "Você não tem permissão pra excluir este bebê."}), 403
        return jsonify({"error": "baby_not_found", "message": "Bebê não encontrado."}), 404

@babies_bp.get("/<int:baby_id>/status")
@jwt_required()
def get_status(baby_id):
    user_id = int(get_jwt_identity())
    try:
        status = baby_service.get_status(baby_id, user_id)
        return jsonify(status), 200
    except ValueError:
        return jsonify({"error": "baby_not_found", "message": "Bebê não encontrado."}), 404

def _serialize_baby_user(baby_user):
    return {
        "user_id": baby_user.user_id,
        "name": baby_user.user.name,
        "username": baby_user.user.username,
        "role": baby_user.role,
        "title": baby_user.title,
    }

@babies_bp.get("/<int:baby_id>/users")
@jwt_required()
def list_baby_users(baby_id):
    user_id = int(get_jwt_identity())
    try:
        baby_users = baby_service.list_baby_users(baby_id, user_id)
        return jsonify([_serialize_baby_user(bu) for bu in baby_users]), 200
    except ValueError as e:
        if str(e) == "forbidden":
            return jsonify({"error": "forbidden", "message": "Você não tem permissão pra ver quem tem acesso a este bebê."}), 403
        return jsonify({"error": "baby_not_found", "message": "Bebê não encontrado."}), 404

@babies_bp.put("/<int:baby_id>/users/<int:target_user_id>")
@jwt_required()
def update_baby_user(baby_id, target_user_id):
    user_id = int(get_jwt_identity())
    data = request.get_json() or {}
    try:
        baby_user = baby_service.update_baby_user(
            baby_id, user_id, target_user_id,
            role=data.get("role"), title=data.get("title")
        )
        return jsonify(_serialize_baby_user(baby_user)), 200
    except ValueError as e:
        error = str(e)
        if error == "forbidden":
            return jsonify({"error": error, "message": "Você não tem permissão pra gerenciar o acesso deste bebê."}), 403
        if error == "baby_not_found":
            return jsonify({"error": error, "message": "Bebê não encontrado."}), 404
        if error == "baby_user_not_found":
            return jsonify({"error": error, "message": "Esta pessoa não tem acesso a este bebê."}), 404
        if error == "invalid_role":
            return jsonify({"error": error, "message": "Nível de permissão inválido."}), 422
        if error == "cannot_remove_last_admin":
            return jsonify({"error": error, "message": "Não é possível rebaixar o único administrador do bebê."}), 409

@babies_bp.delete("/<int:baby_id>/users/<int:target_user_id>")
@jwt_required()
def remove_baby_user(baby_id, target_user_id):
    user_id = int(get_jwt_identity())
    try:
        baby_service.remove_baby_user(baby_id, user_id, target_user_id)
        return "", 204
    except ValueError as e:
        error = str(e)
        if error == "forbidden":
            return jsonify({"error": error, "message": "Você não tem permissão pra gerenciar o acesso deste bebê."}), 403
        if error == "baby_not_found":
            return jsonify({"error": error, "message": "Bebê não encontrado."}), 404
        if error == "baby_user_not_found":
            return jsonify({"error": error, "message": "Esta pessoa não tem acesso a este bebê."}), 404
        if error == "cannot_remove_last_admin":
            return jsonify({"error": error, "message": "Não é possível remover o único administrador do bebê."}), 409
