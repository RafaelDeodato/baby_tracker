from db.base import db
from db.models.nap import Nap

def find_open_by_baby(baby_id: int) -> Nap | None:
    return db.session.execute(
        db.select(Nap).where(
            Nap.baby_id == baby_id,
            Nap.ended_at.is_(None)
        )
    ).scalar_one_or_none()
