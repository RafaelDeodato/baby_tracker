from datetime import datetime
from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity

from app.services import nap_service

naps_bp = Blueprint("naps", __name__)

def _serialize(nap, warning=None):
    data = {
        "id": nap.id,
        "baby_id": nap.baby_id,
        "started_at": nap.started_at.isoformat(),
        "ended_at": nap.ended_at.isoformat() if nap.ended_at else None,
        "duration_minutes": nap.duration_minutes,
        "location": nap.location,
        "light_environment": nap.light_environment,
        "white_noise": nap.white_noise,
        "note": nap.note,
    }
    if warning:
        data["warning"] = warning
    return data

@naps_bp.get("/babies/<int:baby_id>/naps/")
@jwt_required()
def list_naps(baby_id):
    user_id = int(get_jwt_identity())
    try:
        naps = nap_service.list_naps(baby_id, user_id)
        return jsonify([_serialize(n) for n in naps]), 200
    except ValueError:
        return jsonify({"error": "baby_not_found", "message": "Bebê não encontrado."}), 404

@naps_bp.post("/babies/<int:baby_id>/naps/start")
@jwt_required()
def start_nap(baby_id):
    user_id = int(get_jwt_identity())
    data = request.get_json() or {}
    started_at = datetime.fromisoformat(data["started_at"]) if "started_at" in data else None
    try:
        nap = nap_service.start_nap(
            baby_id, user_id, started_at,
            location=data.get("location"), light_environment=data.get("light_environment"),
            white_noise=data.get("white_noise"), note=data.get("note")
        )
        return jsonify(_serialize(nap)), 201
    except ValueError as e:
        error = str(e)
        if error == "baby_not_found":
            return jsonify({"error": error, "message": "Bebê não encontrado."}), 404
        if error == "nap_already_in_progress":
            return jsonify({"error": error, "message": "Já existe uma soneca em andamento."}), 409
        if error == "feeding_in_progress":
            return jsonify({"error": error, "message": "Existe uma mamada em andamento. Finalize-a antes de iniciar uma soneca."}), 409

@naps_bp.post("/naps/<int:nap_id>/finish")
@jwt_required()
def finish_nap(nap_id):
    user_id = int(get_jwt_identity())
    data = request.get_json() or {}
    ended_at = datetime.fromisoformat(data["ended_at"]) if "ended_at" in data else None
    try:
        result = nap_service.finish_nap(nap_id, user_id, ended_at)
        return jsonify(_serialize(result["nap"], result["warning"])), 200
    except ValueError as e:
        error = str(e)
        if error == "nap_not_found":
            return jsonify({"error": error, "message": "Soneca não encontrada."}), 404
        if error == "nap_already_finished":
            return jsonify({"error": error, "message": "Esta soneca já foi finalizada."}), 409
        if error == "invalid_end_time":
            return jsonify({"error": error, "message": "O horário de término deve ser maior que o de início."}), 422

@naps_bp.put("/naps/<int:nap_id>")
@jwt_required()
def update_nap(nap_id):
    user_id = int(get_jwt_identity())
    data = request.get_json() or {}
    started_at = datetime.fromisoformat(data["started_at"]) if "started_at" in data else None
    ended_at = datetime.fromisoformat(data["ended_at"]) if "ended_at" in data else None
    try:
        nap = nap_service.update_nap(
            nap_id, user_id, started_at, ended_at,
            location=data.get("location"), light_environment=data.get("light_environment"),
            white_noise=data.get("white_noise"), note=data.get("note")
        )
        return jsonify(_serialize(nap)), 200
    except ValueError as e:
        error = str(e)
        if error == "nap_not_found":
            return jsonify({"error": error, "message": "Soneca não encontrada."}), 404
        if error == "invalid_end_time":
            return jsonify({"error": error, "message": "O horário de término deve ser maior que o de início."}), 422
        if error == "overlaps_existing_event":
            return jsonify({"error": error, "message": "O novo horário conflita com outro evento já registrado."}), 409

@naps_bp.delete("/naps/<int:nap_id>")
@jwt_required()
def delete_nap(nap_id):
    user_id = int(get_jwt_identity())
    try:
        nap_service.delete_nap(nap_id, user_id)
        return "", 204
    except ValueError:
        return jsonify({"error": "nap_not_found", "message": "Soneca não encontrada."}), 404
