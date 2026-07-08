from flask import Blueprint, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity

from app.services import notification_service

notifications_bp = Blueprint("notifications", __name__)

@notifications_bp.get("/notifications")
@jwt_required()
def list_notifications():
    user_id = int(get_jwt_identity())
    notifications = notification_service.list_notifications(user_id)
    return jsonify(notifications), 200

@notifications_bp.post("/notifications/<int:notification_id>/read")
@jwt_required()
def mark_as_read(notification_id):
    user_id = int(get_jwt_identity())
    try:
        notification_service.mark_as_read(notification_id, user_id)
        return "", 204
    except ValueError:
        return jsonify({"error": "notification_not_found", "message": "Notificação não encontrada."}), 404
