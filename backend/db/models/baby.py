from datetime import datetime, timezone
from db.base import db

class Baby(db.Model):
    __tablename__ = "babies"

    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String, nullable=False)
    birth_date = db.Column(db.Date, nullable=False)
    created_at = db.Column(db.DateTime(timezone=True), nullable=False, default=lambda: datetime.now(timezone.utc))

    feedings = db.relationship("Feeding", back_populates="baby", cascade="all, delete-orphan")
    naps = db.relationship("Nap", back_populates="baby", cascade="all, delete-orphan")
    diapers = db.relationship("Diaper", back_populates="baby", cascade="all, delete-orphan")
    baby_users = db.relationship("BabyUser", back_populates="baby", cascade="all, delete-orphan")
