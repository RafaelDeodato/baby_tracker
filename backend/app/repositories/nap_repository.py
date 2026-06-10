from db.base import db
from db.models.nap import Nap
from db.models.baby import Baby

def find_open_by_baby(baby_id: int) -> Nap | None:
    return db.session.execute(
        db.select(Nap).where(
            Nap.baby_id == baby_id,
            Nap.ended_at.is_(None)
        )
    ).scalar_one_or_none()

def find_by_id_and_user(nap_id: int, user_id: int) -> Nap | None:
    return db.session.execute(
        db.select(Nap)
        .join(Baby)
        .where(Nap.id == nap_id, Baby.user_id == user_id)
    ).scalar_one_or_none()

def list_by_baby(baby_id: int) -> list[Nap]:
    return db.session.execute(
        db.select(Nap)
        .where(Nap.baby_id == baby_id)
        .order_by(Nap.started_at.desc())
    ).scalars().all()

def save(nap: Nap) -> Nap:
    db.session.add(nap)
    db.session.commit()
    return nap

def delete(nap: Nap) -> None:
    db.session.delete(nap)
    db.session.commit()

def find_last_finished_by_baby(baby_id: int) -> Nap | None:
    return db.session.execute(
        db.select(Nap)
        .where(Nap.baby_id == baby_id, Nap.ended_at.is_not(None))
        .order_by(Nap.ended_at.desc())
        .limit(1)
    ).scalar_one_or_none()
