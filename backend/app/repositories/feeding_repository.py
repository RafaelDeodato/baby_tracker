from db.base import db
from db.models.feeding import Feeding
from db.models.baby import Baby

def find_open_by_baby(baby_id: int) -> Feeding | None:
    return db.session.execute(
        db.select(Feeding).where(
            Feeding.baby_id == baby_id,
            Feeding.ended_at.is_(None)
        )
    ).scalar_one_or_none()

def find_by_id_and_user(feeding_id: int, user_id: int) -> Feeding | None:
    return db.session.execute(
        db.select(Feeding)
        .join(Baby)
        .where(Feeding.id == feeding_id, Baby.user_id == user_id)
    ).scalar_one_or_none()

def list_by_baby(baby_id: int) -> list[Feeding]:
    return db.session.execute(
        db.select(Feeding)
        .where(Feeding.baby_id == baby_id)
        .order_by(Feeding.started_at.desc())
    ).scalars().all()

def save(feeding: Feeding) -> Feeding:
    db.session.add(feeding)
    db.session.commit()
    return feeding

def delete(feeding: Feeding) -> None:
    db.session.delete(feeding)
    db.session.commit()
