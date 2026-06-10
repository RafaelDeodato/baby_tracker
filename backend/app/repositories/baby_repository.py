from db.base import db
from db.models.baby import Baby

def find_by_id_and_user(baby_id: int, user_id: int) -> Baby | None:
    return db.session.execute(
        db.select(Baby).where(Baby.id == baby_id, Baby.user_id == user_id)
    ).scalar_one_or_none()

def list_by_user(user_id: int) -> list[Baby]:
    return db.session.execute(
        db.select(Baby).where(Baby.user_id == user_id)
    ).scalars().all()

def save(baby: Baby) -> Baby:
    db.session.add(baby)
    db.session.commit()
    return baby

def delete(baby: Baby) -> None:
    db.session.delete(baby)
    db.session.commit()
