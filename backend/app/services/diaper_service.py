from datetime import datetime, timezone
from db.models.diaper import Diaper
from app.repositories import diaper_repository, baby_repository, feeding_repository

def list_diapers(baby_id: int, user_id: int) -> list[Diaper]:
    baby = baby_repository.find_by_id_and_user(baby_id, user_id)
    if not baby:
        raise ValueError("baby_not_found")
    return diaper_repository.list_by_baby(baby_id)

def register_diaper(
    baby_id: int,
    user_id: int,
    changed_at: datetime | None = None,
    type: str | None = None,
    consistency: str | None = None,
    note: str | None = None
) -> Diaper:
    baby = baby_repository.find_by_id_and_user(baby_id, user_id)
    if not baby:
        raise ValueError("baby_not_found")

    # Troca de fralda é instantânea — sem conceito de "em andamento" e não
    # conflita com soneca (pode trocar com o bebê dormindo). Conflita com
    # mamada: na prática o responsável está com as mãos ocupadas mamando.
    if feeding_repository.find_open_by_baby(baby_id):
        raise ValueError("feeding_in_progress")

    diaper = Diaper(
        baby_id=baby_id,
        changed_at=changed_at or datetime.now(timezone.utc),
        type=type,
        consistency=consistency,
        note=note
    )
    return diaper_repository.save(diaper)

def update_diaper(
    diaper_id: int,
    user_id: int,
    changed_at: datetime | None = None,
    type: str | None = None,
    consistency: str | None = None,
    note: str | None = None
) -> Diaper:
    diaper = diaper_repository.find_by_id_and_user(diaper_id, user_id)
    if not diaper:
        raise ValueError("diaper_not_found")

    if changed_at is not None: diaper.changed_at = changed_at
    if type is not None: diaper.type = type
    if consistency is not None: diaper.consistency = consistency
    if note is not None: diaper.note = note
    return diaper_repository.save(diaper)

def delete_diaper(diaper_id: int, user_id: int) -> None:
    diaper = diaper_repository.find_by_id_and_user(diaper_id, user_id)
    if not diaper:
        raise ValueError("diaper_not_found")
    diaper_repository.delete(diaper)
