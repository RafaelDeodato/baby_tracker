from db.models.notification import Notification
from app.repositories import notification_repository, baby_invite_repository, baby_repository, baby_access_event_repository

def notify(user_id: int, type: str, reference_id: int | None = None) -> Notification:
    return notification_repository.create(user_id=user_id, type=type, reference_id=reference_id)

def list_notifications(user_id: int) -> list[dict]:
    notifications = notification_repository.list_by_user(user_id)
    return [_enrich(n) for n in notifications]

def mark_as_read(notification_id: int, user_id: int) -> Notification:
    notification = notification_repository.find_by_id_and_user(notification_id, user_id)
    if not notification:
        raise ValueError("notification_not_found")
    notification.read = True
    return notification_repository.save(notification)

def _enrich(notification: Notification) -> dict:
    data = {
        "id": notification.id,
        "type": notification.type,
        "read": notification.read,
        "created_at": notification.created_at.isoformat(),
        "invite": None,
        "access": None,
    }

    if notification.type in ("baby_invite_received", "baby_invite_accepted", "baby_invite_declined") and notification.reference_id:
        invite = baby_invite_repository.find_by_id(notification.reference_id)
        if invite:
            baby = baby_repository.find_by_id(invite.baby_id)
            data["invite"] = {
                "id": invite.id,
                "baby": {"id": baby.id, "name": baby.name} if baby else None,
                "role": invite.role,
                "title": invite.title,
                "status": invite.status,
                "invited_by": {"name": invite.invited_by.name, "username": invite.invited_by.username} if invite.invited_by else None,
                "invited_user": {"name": invite.invited_user.name, "username": invite.invited_user.username} if invite.invited_user else None,
            }

    if notification.type == "baby_access_updated" and notification.reference_id:
        event = baby_access_event_repository.find_by_id(notification.reference_id)
        if event:
            baby = baby_repository.find_by_id(event.baby_id)
            data["access"] = {
                "baby": {"id": baby.id, "name": baby.name} if baby else None,
                "role": event.role,
                "title": event.title,
            }

    return data
