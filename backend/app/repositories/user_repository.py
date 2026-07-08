from db.base import db
from db.models.user import User

def find_by_email(email: str) -> User | None:
    return db.session.execute(
        db.select(User).where(User.email == email)
    ).scalar_one_or_none()

def find_by_username(username: str) -> User | None:
    return db.session.execute(
        db.select(User).where(User.username == username)
    ).scalar_one_or_none()

def find_by_id(user_id: int) -> User | None:
    return db.session.get(User, user_id)

def save(user: User) -> User:
    db.session.add(user)
    db.session.commit()
    return user
