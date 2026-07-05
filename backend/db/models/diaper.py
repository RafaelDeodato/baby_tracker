from datetime import datetime, timezone
from db.base import db

class Diaper(db.Model):
    __tablename__ = "diapers"

    id = db.Column(db.Integer, primary_key=True)
    baby_id = db.Column(db.Integer, db.ForeignKey("babies.id", ondelete="CASCADE"), nullable=False)
    changed_at = db.Column(db.DateTime(timezone=True), nullable=False)
    created_at = db.Column(db.DateTime(timezone=True), nullable=False, default=lambda: datetime.now(timezone.utc))

    baby = db.relationship("Baby", back_populates="diapers")
