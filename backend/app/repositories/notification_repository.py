from db.base import db
from db.models.notification import Notification

def create(user_id: int, type: str, reference_id: int | None = None) -> Notification:
    notification = Notification(user_id=user_id, type=type, reference_id=reference_id)
    db.session.add(notification)
    db.session.commit()
    return notification

def list_by_user(user_id: int) -> list[Notification]:
    return db.session.execute(
        db.select(Notification)
        .where(Notification.user_id == user_id)
        .order_by(Notification.created_at.desc())
    ).scalars().all()

def find_by_id_and_user(notification_id: int, user_id: int) -> Notification | None:
    return db.session.execute(
        db.select(Notification).where(Notification.id == notification_id, Notification.user_id == user_id)
    ).scalar_one_or_none()

def save(notification: Notification) -> Notification:
    db.session.add(notification)
    db.session.commit()
    return notification
