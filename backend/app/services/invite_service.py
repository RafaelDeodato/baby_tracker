from datetime import datetime, timezone
from db.models.baby_invite import BabyInvite
from app.repositories import baby_invite_repository, baby_user_repository, user_repository
from app.services.authorization_service import require_role, ROLES_CAN_MANAGE_BABY, ALL_ROLES
from app.services import notification_service

def create_invite(baby_id: int, inviter_id: int, username: str, role: str, title: str | None = None) -> BabyInvite:
    require_role(baby_id, inviter_id, ROLES_CAN_MANAGE_BABY)

    if role not in ALL_ROLES:
        raise ValueError("invalid_role")

    invited_user = user_repository.find_by_username(username)
    if not invited_user:
        raise ValueError("user_not_found")

    if baby_user_repository.find_by_baby_and_user(baby_id, invited_user.id):
        raise ValueError("user_already_has_access")

    if baby_invite_repository.find_pending_by_baby_and_user(baby_id, invited_user.id):
        raise ValueError("invite_already_pending")

    invite = BabyInvite(
        baby_id=baby_id,
        invited_user_id=invited_user.id,
        invited_by_id=inviter_id,
        role=role,
        title=title
    )
    invite = baby_invite_repository.save(invite)
    notification_service.notify(user_id=invited_user.id, type="baby_invite_received", reference_id=invite.id)
    return invite

def list_received_invites(user_id: int) -> list[BabyInvite]:
    return baby_invite_repository.list_pending_by_user(user_id)

def accept_invite(invite_id: int, user_id: int) -> BabyInvite:
    invite = _find_pending_invite_for_user(invite_id, user_id)

    baby_user_repository.add(baby_id=invite.baby_id, user_id=user_id, role=invite.role, title=invite.title)

    invite.status = "accepted"
    invite.resolved_at = datetime.now(timezone.utc)
    baby_invite_repository.save(invite)

    notification_service.notify(user_id=invite.invited_by_id, type="baby_invite_accepted", reference_id=invite.id)
    return invite

def decline_invite(invite_id: int, user_id: int) -> BabyInvite:
    invite = _find_pending_invite_for_user(invite_id, user_id)

    invite.status = "declined"
    invite.resolved_at = datetime.now(timezone.utc)
    baby_invite_repository.save(invite)

    notification_service.notify(user_id=invite.invited_by_id, type="baby_invite_declined", reference_id=invite.id)
    return invite

def _find_pending_invite_for_user(invite_id: int, user_id: int) -> BabyInvite:
    invite = baby_invite_repository.find_by_id(invite_id)
    if not invite or invite.invited_user_id != user_id:
        raise ValueError("invite_not_found")
    if invite.status != "pending":
        raise ValueError("invite_already_resolved")
    return invite
