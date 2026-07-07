from datetime import datetime, timezone
from db.base import db

class RevokedToken(db.Model):
    __tablename__ = "revoked_tokens"

    jti = db.Column(db.String, primary_key=True)
    revoked_at = db.Column(db.DateTime(timezone=True), nullable=False, default=lambda: datetime.now(timezone.utc))
