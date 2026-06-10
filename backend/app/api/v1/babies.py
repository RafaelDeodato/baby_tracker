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
    except ValueError:
        return jsonify({"error": "baby_not_found", "message": "Bebê não encontrado."}), 404

@babies_bp.delete("/<int:baby_id>")
@jwt_required()
def delete_baby(baby_id):
    user_id = int(get_jwt_identity())
    try:
        baby_service.delete_baby(baby_id, user_id)
        return "", 204
    except ValueError:
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
