from datetime import datetime, timezone
from db.models.nap import Nap
from app.repositories import nap_repository, feeding_repository, baby_repository

NAP_WARNING_MINUTES = 960  # 16 horas

def list_naps(baby_id: int, user_id: int) -> list[Nap]:
    baby = baby_repository.find_by_id_and_user(baby_id, user_id)
    if not baby:
        raise ValueError("baby_not_found")
    return nap_repository.list_by_baby(baby_id)

def start_nap(baby_id: int, user_id: int, started_at: datetime | None = None) -> Nap:
    baby = baby_repository.find_by_id_and_user(baby_id, user_id)
    if not baby:
        raise ValueError("baby_not_found")

    if nap_repository.find_open_by_baby(baby_id):
        raise ValueError("nap_already_in_progress")

    if feeding_repository.find_open_by_baby(baby_id):
        raise ValueError("feeding_in_progress")

    nap = Nap(
        baby_id=baby_id,
        started_at=started_at or datetime.now(timezone.utc)
    )
    return nap_repository.save(nap)

def finish_nap(nap_id: int, user_id: int, ended_at: datetime | None = None) -> dict:
    nap = nap_repository.find_by_id_and_user(nap_id, user_id)
    if not nap:
        raise ValueError("nap_not_found")

    if nap.ended_at is not None:
        raise ValueError("nap_already_finished")

    ended_at = ended_at or datetime.now(timezone.utc)

    if ended_at <= nap.started_at:
        raise ValueError("invalid_end_time")

    nap.ended_at = ended_at
    nap_repository.save(nap)

    warning = None
    if nap.duration_minutes > NAP_WARNING_MINUTES:
        warning = "Duração improvável. O registro pode ter ficado aberto por engano."

    return {"nap": nap, "warning": warning}

def update_nap(
    nap_id: int,
    user_id: int,
    started_at: datetime | None = None,
    ended_at: datetime | None = None
) -> Nap:
    nap = nap_repository.find_by_id_and_user(nap_id, user_id)
    if not nap:
        raise ValueError("nap_not_found")

    new_started_at = started_at if started_at is not None else nap.started_at
    new_ended_at = ended_at if ended_at is not None else nap.ended_at

    if new_ended_at is not None and new_ended_at <= new_started_at:
        raise ValueError("invalid_end_time")

    if nap_repository.find_overlapping(nap.baby_id, new_started_at, new_ended_at, exclude_id=nap.id):
        raise ValueError("overlaps_existing_event")
    if feeding_repository.find_overlapping(nap.baby_id, new_started_at, new_ended_at):
        raise ValueError("overlaps_existing_event")

    nap.started_at = new_started_at
    nap.ended_at = new_ended_at
    return nap_repository.save(nap)

def delete_nap(nap_id: int, user_id: int) -> None:
    nap = nap_repository.find_by_id_and_user(nap_id, user_id)
    if not nap:
        raise ValueError("nap_not_found")
    nap_repository.delete(nap)
