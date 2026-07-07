from db.base import db
from db.models.revoked_token import RevokedToken

def is_revoked(jti: str) -> bool:
    return db.session.get(RevokedToken, jti) is not None

def add(jti: str) -> None:
    if is_revoked(jti):
        return
    db.session.add(RevokedToken(jti=jti))
    db.session.commit()
