from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity

from app.services import invite_service

invites_bp = Blueprint("invites", __name__)

def _serialize(invite):
    return {
        "id": invite.id,
        "baby_id": invite.baby_id,
        "role": invite.role,
        "title": invite.title,
        "status": invite.status,
        "created_at": invite.created_at.isoformat(),
        "invited_by": {"name": invite.invited_by.name, "username": invite.invited_by.username},
        "baby_name": invite.baby.name if invite.baby else None,
    }

@invites_bp.post("/babies/<int:baby_id>/invites")
@jwt_required()
def create_invite(baby_id):
    user_id = int(get_jwt_identity())
    data = request.get_json() or {}
    try:
        invite = invite_service.create_invite(
            baby_id, user_id,
            username=data.get("username"),
            role=data.get("role"),
            title=data.get("title")
        )
        return jsonify(_serialize(invite)), 201
    except ValueError as e:
        error = str(e)
        if error == "baby_not_found":
            return jsonify({"error": error, "message": "Bebê não encontrado."}), 404
        if error == "forbidden":
            return jsonify({"error": error, "message": "Você não tem permissão pra convidar para este bebê."}), 403
        if error == "invalid_role":
            return jsonify({"error": error, "message": "Nível de permissão inválido."}), 422
        if error == "user_not_found":
            return jsonify({"error": error, "message": "Usuário não encontrado. Peça pra essa pessoa se cadastrar primeiro."}), 404
        if error == "user_already_has_access":
            return jsonify({"error": error, "message": "Este usuário já tem acesso a este bebê."}), 409
        if error == "invite_already_pending":
            return jsonify({"error": error, "message": "Já existe um convite pendente para este usuário."}), 409

@invites_bp.get("/invites")
@jwt_required()
def list_invites():
    user_id = int(get_jwt_identity())
    invites = invite_service.list_received_invites(user_id)
    return jsonify([_serialize(i) for i in invites]), 200

@invites_bp.post("/invites/<int:invite_id>/accept")
@jwt_required()
def accept_invite(invite_id):
    user_id = int(get_jwt_identity())
    try:
        invite = invite_service.accept_invite(invite_id, user_id)
        return jsonify(_serialize(invite)), 200
    except ValueError as e:
        error = str(e)
        if error == "invite_not_found":
            return jsonify({"error": error, "message": "Convite não encontrado."}), 404
        if error == "invite_already_resolved":
            return jsonify({"error": error, "message": "Este convite já foi respondido."}), 409

@invites_bp.post("/invites/<int:invite_id>/decline")
@jwt_required()
def decline_invite(invite_id):
    user_id = int(get_jwt_identity())
    try:
        invite = invite_service.decline_invite(invite_id, user_id)
        return jsonify(_serialize(invite)), 200
    except ValueError as e:
        error = str(e)
        if error == "invite_not_found":
            return jsonify({"error": error, "message": "Convite não encontrado."}), 404
        if error == "invite_already_resolved":
            return jsonify({"error": error, "message": "Este convite já foi respondido."}), 409
