from datetime import datetime
from sqlalchemy import or_
from db.base import db
from db.models.feeding import Feeding
from db.models.baby_user import BabyUser

def find_overlapping(
    baby_id: int,
    started_at: datetime,
    ended_at: datetime | None,
    exclude_id: int | None = None
) -> Feeding | None:
    conditions = [
        Feeding.baby_id == baby_id,
        or_(Feeding.ended_at.is_(None), Feeding.ended_at > started_at),
    ]
    if ended_at is not None:
        conditions.append(Feeding.started_at < ended_at)
    if exclude_id is not None:
        conditions.append(Feeding.id != exclude_id)

    return db.session.execute(db.select(Feeding).where(*conditions)).scalars().first()

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
        .join(BabyUser, BabyUser.baby_id == Feeding.baby_id)
        .where(Feeding.id == feeding_id, BabyUser.user_id == user_id)
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

def find_last_finished_by_baby(baby_id: int) -> Feeding | None:
    return db.session.execute(
        db.select(Feeding)
        .where(Feeding.baby_id == baby_id, Feeding.ended_at.is_not(None))
        .order_by(Feeding.ended_at.desc())
        .limit(1)
    ).scalar_one_or_none()
