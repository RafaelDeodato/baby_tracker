from datetime import datetime
from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity

from app.services import feeding_service

feedings_bp = Blueprint("feedings", __name__)

def _serialize(feeding, warning=None):
    data = {
        "id": feeding.id,
        "baby_id": feeding.baby_id,
        "started_at": feeding.started_at.isoformat(),
        "ended_at": feeding.ended_at.isoformat() if feeding.ended_at else None,
        "duration_minutes": feeding.duration_minutes,
        "type": feeding.type,
        "side": feeding.side,
        "volume_ml": feeding.volume_ml,
        "note": feeding.note,
    }
    if warning:
        data["warning"] = warning
    return data

@feedings_bp.get("/babies/<int:baby_id>/feedings/")
@jwt_required()
def list_feedings(baby_id):
    user_id = int(get_jwt_identity())
    try:
        feedings = feeding_service.list_feedings(baby_id, user_id)
        return jsonify([_serialize(f) for f in feedings]), 200
    except ValueError:
        return jsonify({"error": "baby_not_found", "message": "Bebê não encontrado."}), 404

@feedings_bp.post("/babies/<int:baby_id>/feedings/start")
@jwt_required()
def start_feeding(baby_id):
    user_id = int(get_jwt_identity())
    data = request.get_json() or {}
    started_at = datetime.fromisoformat(data["started_at"]) if "started_at" in data else None
    try:
        feeding = feeding_service.start_feeding(
            baby_id, user_id, started_at,
            type=data.get("type"), side=data.get("side"),
            volume_ml=data.get("volume_ml"), note=data.get("note")
        )
        return jsonify(_serialize(feeding)), 201
    except ValueError as e:
        error = str(e)
        if error == "baby_not_found":
            return jsonify({"error": error, "message": "Bebê não encontrado."}), 404
        if error == "feeding_already_in_progress":
            return jsonify({"error": error, "message": "Já existe uma mamada em andamento."}), 409
        if error == "nap_in_progress":
            return jsonify({"error": error, "message": "Existe uma soneca em andamento. Finalize-a antes de iniciar uma mamada."}), 409
        if error == "forbidden":
            return jsonify({"error": error, "message": "Você não tem permissão pra registrar mamada para este bebê."}), 403

@feedings_bp.post("/feedings/<int:feeding_id>/finish")
@jwt_required()
def finish_feeding(feeding_id):
    user_id = int(get_jwt_identity())
    data = request.get_json() or {}
    ended_at = datetime.fromisoformat(data["ended_at"]) if "ended_at" in data else None
    try:
        result = feeding_service.finish_feeding(feeding_id, user_id, ended_at)
        return jsonify(_serialize(result["feeding"], result["warning"])), 200
    except ValueError as e:
        error = str(e)
        if error == "feeding_not_found":
            return jsonify({"error": error, "message": "Mamada não encontrada."}), 404
        if error == "feeding_already_finished":
            return jsonify({"error": error, "message": "Esta mamada já foi finalizada."}), 409
        if error == "invalid_end_time":
            return jsonify({"error": error, "message": "O horário de término deve ser maior que o de início."}), 422
        if error == "forbidden":
            return jsonify({"error": error, "message": "Você não tem permissão pra finalizar esta mamada."}), 403

@feedings_bp.put("/feedings/<int:feeding_id>")
@jwt_required()
def update_feeding(feeding_id):
    user_id = int(get_jwt_identity())
    data = request.get_json() or {}
    started_at = datetime.fromisoformat(data["started_at"]) if "started_at" in data else None
    ended_at = datetime.fromisoformat(data["ended_at"]) if "ended_at" in data else None
    try:
        feeding = feeding_service.update_feeding(
            feeding_id, user_id, started_at, ended_at,
            type=data.get("type"), side=data.get("side"),
            volume_ml=data.get("volume_ml"), note=data.get("note")
        )
        return jsonify(_serialize(feeding)), 200
    except ValueError as e:
        error = str(e)
        if error == "feeding_not_found":
            return jsonify({"error": error, "message": "Mamada não encontrada."}), 404
        if error == "invalid_end_time":
            return jsonify({"error": error, "message": "O horário de término deve ser maior que o de início."}), 422
        if error == "overlaps_existing_event":
            return jsonify({"error": error, "message": "O novo horário conflita com outro evento já registrado."}), 409
        if error == "forbidden":
            return jsonify({"error": error, "message": "Você não tem permissão pra editar esta mamada."}), 403

@feedings_bp.delete("/feedings/<int:feeding_id>")
@jwt_required()
def delete_feeding(feeding_id):
    user_id = int(get_jwt_identity())
    try:
        feeding_service.delete_feeding(feeding_id, user_id)
        return "", 204
    except ValueError as e:
        if str(e) == "forbidden":
            return jsonify({"error": "forbidden", "message": "Você não tem permissão pra excluir esta mamada."}), 403
        return jsonify({"error": "feeding_not_found", "message": "Mamada não encontrada."}), 404
