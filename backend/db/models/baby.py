from datetime import datetime, timezone
from db.base import db

class Baby(db.Model):
    __tablename__ = "babies"

    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey("users.id"), nullable=False)
    name = db.Column(db.String, nullable=False)
    birth_date = db.Column(db.Date, nullable=False)
    created_at = db.Column(db.DateTime(timezone=True), nullable=False, default=lambda: datetime.now(timezone.utc))

    user = db.relationship("User", back_populates="babies")
    feedings = db.relationship("Feeding", back_populates="baby", cascade="all, delete-orphan")
    naps = db.relationship("Nap", back_populates="baby", cascade="all, delete-orphan")
