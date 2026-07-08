from db.base import db
from db.models.baby_invite import BabyInvite

def find_by_id(invite_id: int) -> BabyInvite | None:
    return db.session.get(BabyInvite, invite_id)

def find_pending_by_baby_and_user(baby_id: int, invited_user_id: int) -> BabyInvite | None:
    return db.session.execute(
        db.select(BabyInvite).where(
            BabyInvite.baby_id == baby_id,
            BabyInvite.invited_user_id == invited_user_id,
            BabyInvite.status == "pending"
        )
    ).scalar_one_or_none()

def list_pending_by_user(user_id: int) -> list[BabyInvite]:
    return db.session.execute(
        db.select(BabyInvite)
        .where(BabyInvite.invited_user_id == user_id, BabyInvite.status == "pending")
        .order_by(BabyInvite.created_at.desc())
    ).scalars().all()

def save(invite: BabyInvite) -> BabyInvite:
    db.session.add(invite)
    db.session.commit()
    return invite
