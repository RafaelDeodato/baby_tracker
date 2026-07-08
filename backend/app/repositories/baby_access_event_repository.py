from db.base import db
from db.models.baby_access_event import BabyAccessEvent

def create(baby_id: int, user_id: int, changed_by_id: int, role: str, title: str | None = None) -> BabyAccessEvent:
    event = BabyAccessEvent(baby_id=baby_id, user_id=user_id, changed_by_id=changed_by_id, role=role, title=title)
    db.session.add(event)
    db.session.commit()
    return event

def find_by_id(event_id: int) -> BabyAccessEvent | None:
    return db.session.get(BabyAccessEvent, event_id)
