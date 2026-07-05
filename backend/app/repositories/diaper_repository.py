from db.base import db
from db.models.diaper import Diaper
from db.models.baby import Baby

def find_by_id_and_user(diaper_id: int, user_id: int) -> Diaper | None:
    return db.session.execute(
        db.select(Diaper)
        .join(Baby)
        .where(Diaper.id == diaper_id, Baby.user_id == user_id)
    ).scalar_one_or_none()

def list_by_baby(baby_id: int) -> list[Diaper]:
    return db.session.execute(
        db.select(Diaper)
        .where(Diaper.baby_id == baby_id)
        .order_by(Diaper.changed_at.desc())
    ).scalars().all()

def save(diaper: Diaper) -> Diaper:
    db.session.add(diaper)
    db.session.commit()
    return diaper

def delete(diaper: Diaper) -> None:
    db.session.delete(diaper)
    db.session.commit()

def find_last_by_baby(baby_id: int) -> Diaper | None:
    return db.session.execute(
        db.select(Diaper)
        .where(Diaper.baby_id == baby_id)
        .order_by(Diaper.changed_at.desc())
        .limit(1)
    ).scalar_one_or_none()
