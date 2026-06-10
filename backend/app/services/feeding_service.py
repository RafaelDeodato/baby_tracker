from datetime import datetime, timezone
from db.models.feeding import Feeding
from app.repositories import feeding_repository, nap_repository, baby_repository

FEEDING_WARNING_MINUTES = 180 # 3 horas

def list_feedings(baby_id: int, user_id: int) -> list[Feeding]:
    baby = baby_repository.find_by_id_and_user(baby_id, user_id)
    if not baby:
        raise ValueError("baby_not_found")
    return feeding_repository.list_by_baby(baby_id)

def start_feeding(baby_id: int, user_id: int, started_at: datetime | None = None) -> Feeding:
    baby = baby_repository.find_by_id_and_user(baby_id, user_id)
    if not baby:
        raise ValueError("baby_not_found")

    if feeding_repository.find_open_by_baby(baby_id):
        raise ValueError("feeding_already_in_progress")

    if nap_repository.find_open_by_baby(baby_id):
        raise ValueError("nap_in_progress")

    feeding = Feeding(
        baby_id=baby_id,
        started_at=started_at or datetime.now(timezone.utc)
    )
    return feeding_repository.save(feeding)

def finish_feeding(feeding_id: int, user_id: int, ended_at: datetime | None = None) -> dict:
    feeding = feeding_repository.find_by_id_and_user(feeding_id, user_id)
    if not feeding:
        raise ValueError("feeding_not_found")

    if feeding.ended_at is not None:
        raise ValueError("feeding_already_finished")

    ended_at = ended_at or datetime.now(timezone.utc)

    if ended_at <= feeding.started_at:
        raise ValueError("invalid_end_time")

    feeding.ended_at = ended_at
    feeding_repository.save(feeding)

    warning = None
    if feeding.duration_minutes > FEEDING_WARNING_MINUTES:
        warning = "Duração improvável. O registro pode ter ficado aberto por engano."

    return {"feeding": feeding, "warning": warning}

def delete_feeding(feeding_id: int, user_id: int) -> None:
    feeding = feeding_repository.find_by_id_and_user(feeding_id, user_id)
    if not feeding:
        raise ValueError("feeding_not_found")
    feeding_repository.delete(feeding)
