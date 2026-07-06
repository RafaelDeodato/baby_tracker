from datetime import datetime, timezone, date
from db.models.baby import Baby
from app.repositories import baby_repository, feeding_repository, nap_repository, diaper_repository


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

def get_status(baby_id: int, user_id: int) -> dict:
    baby = baby_repository.find_by_id_and_user(baby_id, user_id)
    if not baby:
        raise ValueError("baby_not_found")

    now = datetime.now(timezone.utc)

    current_feeding = feeding_repository.find_open_by_baby(baby_id)
    current_nap = nap_repository.find_open_by_baby(baby_id)
    last_feeding = feeding_repository.find_last_finished_by_baby(baby_id)
    last_nap = nap_repository.find_last_finished_by_baby(baby_id)
    last_diaper = diaper_repository.find_last_by_baby(baby_id)

    return {
        "baby_id": baby_id,
        "current_feeding": {
            "id": current_feeding.id,
            "started_at": current_feeding.started_at.isoformat(),
            "elapsed_minutes": round((now - current_feeding.started_at).total_seconds() / 60),
            "type": current_feeding.type,
            "side": current_feeding.side,
            "volume_ml": current_feeding.volume_ml,
            "note": current_feeding.note,
        } if current_feeding else None,
        "current_nap": {
            "id": current_nap.id,
            "started_at": current_nap.started_at.isoformat(),
            "elapsed_minutes": round((now - current_nap.started_at).total_seconds() / 60),
            "location": current_nap.location,
            "light_environment": current_nap.light_environment,
            "white_noise": current_nap.white_noise,
            "note": current_nap.note,
        } if current_nap else None,
        "last_feeding": {
            "id": last_feeding.id,
            "started_at": last_feeding.started_at.isoformat(),
            "ended_at": last_feeding.ended_at.isoformat(),
            "duration_minutes": last_feeding.duration_minutes,
            "minutes_since_end": round((now - last_feeding.ended_at).total_seconds() / 60),
            "type": last_feeding.type,
            "side": last_feeding.side,
            "volume_ml": last_feeding.volume_ml,
            "note": last_feeding.note,
        } if last_feeding else None,
        "last_nap": {
            "id": last_nap.id,
            "started_at": last_nap.started_at.isoformat(),
            "ended_at": last_nap.ended_at.isoformat(),
            "duration_minutes": last_nap.duration_minutes,
            "location": last_nap.location,
            "light_environment": last_nap.light_environment,
            "white_noise": last_nap.white_noise,
            "note": last_nap.note,
        } if last_nap else None,
        "awake_minutes": round((now - last_nap.ended_at).total_seconds() / 60) if last_nap and not current_nap else None,
        "last_diaper": {
            "id": last_diaper.id,
            "changed_at": last_diaper.changed_at.isoformat(),
            "minutes_since": round((now - last_diaper.changed_at).total_seconds() / 60),
            "type": last_diaper.type,
            "consistency": last_diaper.consistency,
            "note": last_diaper.note,
        } if last_diaper else None
    }