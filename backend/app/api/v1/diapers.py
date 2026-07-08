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
        "type": diaper.type,
        "consistency": diaper.consistency,
        "note": diaper.note,
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
        diaper = diaper_service.register_diaper(
            baby_id, user_id, changed_at,
            type=data.get("type"), consistency=data.get("consistency"), note=data.get("note")
        )
        return jsonify(_serialize(diaper)), 201
    except ValueError as e:
        error = str(e)
        if error == "baby_not_found":
            return jsonify({"error": error, "message": "Bebê não encontrado."}), 404
        if error == "feeding_in_progress":
            return jsonify({"error": error, "message": "Existe uma mamada em andamento. Finalize-a antes de registrar a troca de fralda."}), 409
        if error == "forbidden":
            return jsonify({"error": error, "message": "Você não tem permissão pra registrar troca de fralda para este bebê."}), 403

@diapers_bp.put("/diapers/<int:diaper_id>")
@jwt_required()
def update_diaper(diaper_id):
    user_id = int(get_jwt_identity())
    data = request.get_json() or {}
    changed_at = datetime.fromisoformat(data["changed_at"]) if "changed_at" in data else None
    try:
        diaper = diaper_service.update_diaper(
            diaper_id, user_id, changed_at,
            type=data.get("type"), consistency=data.get("consistency"), note=data.get("note")
        )
        return jsonify(_serialize(diaper)), 200
    except ValueError as e:
        if str(e) == "forbidden":
            return jsonify({"error": "forbidden", "message": "Você não tem permissão pra editar este registro de fralda."}), 403
        return jsonify({"error": "diaper_not_found", "message": "Registro de fralda não encontrado."}), 404

@diapers_bp.delete("/diapers/<int:diaper_id>")
@jwt_required()
def delete_diaper(diaper_id):
    user_id = int(get_jwt_identity())
    try:
        diaper_service.delete_diaper(diaper_id, user_id)
        return "", 204
    except ValueError as e:
        if str(e) == "forbidden":
            return jsonify({"error": "forbidden", "message": "Você não tem permissão pra excluir este registro de fralda."}), 403
        return jsonify({"error": "diaper_not_found", "message": "Registro de fralda não encontrado."}), 404
