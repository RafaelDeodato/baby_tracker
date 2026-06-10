from db.models.baby import Baby
from app.repositories import baby_repository
from datetime import date

def list_babies(user_id: int) -> list[Baby]:
    return baby_repository.list_by_user(user_id)

def get_baby(baby_id: int, user_id: int) -> Baby:
    baby = baby_repository.find_by_id_and_user(baby_id, user_id)
    if not baby:
        raise ValueError("baby_not_found")
    return baby

def create_baby(user_id: int, name: str, birth_date: date) -> Baby:
    baby = Baby(user_id=user_id, name=name, birth_date=birth_date)
    return baby_repository.save(baby)

def update_baby(baby_id: int, user_id: int, name: str, birth_date: date) -> Baby:
    baby = get_baby(baby_id, user_id)
    baby.name = name
    baby.birth_date = birth_date
    return baby_repository.save(baby)

def delete_baby(baby_id: int, user_id: int) -> None:
    baby = get_baby(baby_id, user_id)
    baby_repository.delete(baby)
