from db.base import db
from db.models.baby_user import BabyUser

def find_role(baby_id: int, user_id: int) -> str | None:
    baby_user = find_by_baby_and_user(baby_id, user_id)
    return baby_user.role if baby_user else None

def find_by_baby_and_user(baby_id: int, user_id: int) -> BabyUser | None:
    return db.session.execute(
        db.select(BabyUser).where(BabyUser.baby_id == baby_id, BabyUser.user_id == user_id)
    ).scalar_one_or_none()

def list_by_baby(baby_id: int) -> list[BabyUser]:
    return db.session.execute(
        db.select(BabyUser).where(BabyUser.baby_id == baby_id)
    ).scalars().all()

def list_baby_ids_for_user(user_id: int) -> list[int]:
    rows = db.session.execute(
        db.select(BabyUser.baby_id).where(BabyUser.user_id == user_id)
    ).scalars().all()
    return list(rows)

def add(baby_id: int, user_id: int, role: str, title: str | None = None) -> BabyUser:
    baby_user = BabyUser(baby_id=baby_id, user_id=user_id, role=role, title=title)
    db.session.add(baby_user)
    db.session.commit()
    return baby_user

def save(baby_user: BabyUser) -> BabyUser:
    db.session.add(baby_user)
    db.session.commit()
    return baby_user

def delete(baby_user: BabyUser) -> None:
    db.session.delete(baby_user)
    db.session.commit()
