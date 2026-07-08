from datetime import datetime, timezone
from db.base import db

class BabyAccessEvent(db.Model):
    """Registro imutável de uma mudança de papel/título de acesso a um
    bebê — cada mudança gera uma linha nova, nunca reaproveitada, pra
    que uma notification possa apontar pro estado exato daquele
    momento (mesmo padrão de baby_invites: reference_id aponta pra um
    registro que não muda depois de criado)."""
    __tablename__ = "baby_access_events"

    id = db.Column(db.Integer, primary_key=True)
    baby_id = db.Column(db.Integer, db.ForeignKey("babies.id", ondelete="CASCADE"), nullable=False)
    user_id = db.Column(db.Integer, db.ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    changed_by_id = db.Column(db.Integer, db.ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    role = db.Column(db.String, nullable=False)
    title = db.Column(db.String, nullable=True)
    created_at = db.Column(db.DateTime(timezone=True), nullable=False, default=lambda: datetime.now(timezone.utc))

    baby = db.relationship("Baby")
    user = db.relationship("User", foreign_keys=[user_id])
    changed_by = db.relationship("User", foreign_keys=[changed_by_id])
