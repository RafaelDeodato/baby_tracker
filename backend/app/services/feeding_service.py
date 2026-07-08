from datetime import datetime, timezone
from db.models.feeding import Feeding
from app.repositories import feeding_repository, nap_repository, baby_repository
from app.services.authorization_service import require_role, ROLES_CAN_EDIT_ROUTINE

FEEDING_WARNING_MINUTES = 180 # 3 horas

def list_feedings(baby_id: int, user_id: int) -> list[Feeding]:
    baby = baby_repository.find_by_id_and_user(baby_id, user_id)
    if not baby:
        raise ValueError("baby_not_found")
    return feeding_repository.list_by_baby(baby_id)

def start_feeding(
    baby_id: int,
    user_id: int,
    started_at: datetime | None = None,
    type: str | None = None,
    side: str | None = None,
    volume_ml: int | None = None,
    note: str | None = None
) -> Feeding:
    require_role(baby_id, user_id, ROLES_CAN_EDIT_ROUTINE)

    if feeding_repository.find_open_by_baby(baby_id):
        raise ValueError("feeding_already_in_progress")

    if nap_repository.find_open_by_baby(baby_id):
        raise ValueError("nap_in_progress")

    feeding = Feeding(
        baby_id=baby_id,
        started_at=started_at or datetime.now(timezone.utc),
        type=type,
        side=side,
        volume_ml=volume_ml,
        note=note
    )
    return feeding_repository.save(feeding)

def finish_feeding(feeding_id: int, user_id: int, ended_at: datetime | None = None) -> dict:
    feeding = feeding_repository.find_by_id_and_user(feeding_id, user_id)
    if not feeding:
        raise ValueError("feeding_not_found")
    require_role(feeding.baby_id, user_id, ROLES_CAN_EDIT_ROUTINE)

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

def update_feeding(
    feeding_id: int,
    user_id: int,
    started_at: datetime | None = None,
    ended_at: datetime | None = None,
    type: str | None = None,
    side: str | None = None,
    volume_ml: int | None = None,
    note: str | None = None
) -> Feeding:
    feeding = feeding_repository.find_by_id_and_user(feeding_id, user_id)
    if not feeding:
        raise ValueError("feeding_not_found")
    require_role(feeding.baby_id, user_id, ROLES_CAN_EDIT_ROUTINE)

    new_started_at = started_at if started_at is not None else feeding.started_at
    new_ended_at = ended_at if ended_at is not None else feeding.ended_at

    if new_ended_at is not None and new_ended_at <= new_started_at:
        raise ValueError("invalid_end_time")

    if feeding_repository.find_overlapping(feeding.baby_id, new_started_at, new_ended_at, exclude_id=feeding.id):
        raise ValueError("overlaps_existing_event")
    if nap_repository.find_overlapping(feeding.baby_id, new_started_at, new_ended_at):
        raise ValueError("overlaps_existing_event")

    feeding.started_at = new_started_at
    feeding.ended_at = new_ended_at
    # Update parcial — só sobrescreve os campos de complementação (V3) que
    # vieram preenchidos na requisição.
    if type is not None: feeding.type = type
    if side is not None: feeding.side = side
    if volume_ml is not None: feeding.volume_ml = volume_ml
    if note is not None: feeding.note = note
    return feeding_repository.save(feeding)

def delete_feeding(feeding_id: int, user_id: int) -> None:
    feeding = feeding_repository.find_by_id_and_user(feeding_id, user_id)
    if not feeding:
        raise ValueError("feeding_not_found")
    require_role(feeding.baby_id, user_id, ROLES_CAN_EDIT_ROUTINE)
    feeding_repository.delete(feeding)
