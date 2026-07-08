from datetime import datetime, timezone
from db.base import db

class BabyInvite(db.Model):
    __tablename__ = "baby_invites"

    id = db.Column(db.Integer, primary_key=True)
    baby_id = db.Column(db.Integer, db.ForeignKey("babies.id", ondelete="CASCADE"), nullable=False)
    invited_user_id = db.Column(db.Integer, db.ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    invited_by_id = db.Column(db.Integer, db.ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    role = db.Column(db.String, nullable=False)  # 'adm' | 'tutor' | 'visualizador'
    title = db.Column(db.String, nullable=True)
    status = db.Column(db.String, nullable=False, default="pending")  # 'pending' | 'accepted' | 'declined'
    created_at = db.Column(db.DateTime(timezone=True), nullable=False, default=lambda: datetime.now(timezone.utc))
    resolved_at = db.Column(db.DateTime(timezone=True), nullable=True)

    baby = db.relationship("Baby")
    invited_user = db.relationship("User", foreign_keys=[invited_user_id])
    invited_by = db.relationship("User", foreign_keys=[invited_by_id])
