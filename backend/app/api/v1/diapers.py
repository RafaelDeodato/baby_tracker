from datetime import datetime
from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity

from app.services import diaper_service

diapers_bp = Blueprint("diapers", __name__)

def _serialize(diaper):
    return {
        "id": diaper.id,
        "baby_id": diaper.baby_id,
        "changed_at": diaper.changed_at.isoformat(),
    }

@diapers_bp.get("/babies/<int:baby_id>/diapers/")
@jwt_required()
def list_diapers(baby_id):
    user_id = int(get_jwt_identity())
    try:
        diapers = diaper_service.list_diapers(baby_id, user_id)
        return jsonify([_serialize(d) for d in diapers]), 200
    except ValueError:
        return jsonify({"error": "baby_not_found", "message": "Bebê não encontrado."}), 404

@diapers_bp.post("/babies/<int:baby_id>/diapers/")
@jwt_required()
def register_diaper(baby_id):
    user_id = int(get_jwt_identity())
    data = request.get_json() or {}
    changed_at = datetime.fromisoformat(data["changed_at"]) if "changed_at" in data else None
    try:
        diaper = diaper_service.register_diaper(baby_id, user_id, changed_at)
        return jsonify(_serialize(diaper)), 201
    except ValueError as e:
        error = str(e)
        if error == "baby_not_found":
            return jsonify({"error": error, "message": "Bebê não encontrado."}), 404
        if error == "feeding_in_progress":
            return jsonify({"error": error, "message": "Existe uma mamada em andamento. Finalize-a antes de registrar a troca de fralda."}), 409

@diapers_bp.put("/diapers/<int:diaper_id>")
@jwt_required()
def update_diaper(diaper_id):
    user_id = int(get_jwt_identity())
    data = request.get_json() or {}
    if "changed_at" not in data:
        return jsonify({"error": "invalid_payload", "message": "changed_at é obrigatório."}), 422
    try:
        diaper = diaper_service.update_diaper(diaper_id, user_id, datetime.fromisoformat(data["changed_at"]))
        return jsonify(_serialize(diaper)), 200
    except ValueError:
        return jsonify({"error": "diaper_not_found", "message": "Registro de fralda não encontrado."}), 404

@diapers_bp.delete("/diapers/<int:diaper_id>")
@jwt_required()
def delete_diaper(diaper_id):
    user_id = int(get_jwt_identity())
    try:
        diaper_service.delete_diaper(diaper_id, user_id)
        return "", 204
    except ValueError:
        return jsonify({"error": "diaper_not_found", "message": "Registro de fralda não encontrado."}), 404
