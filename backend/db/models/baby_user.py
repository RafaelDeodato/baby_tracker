from datetime import datetime, timezone
from db.base import db

class BabyUser(db.Model):
    __tablename__ = "baby_users"
    __table_args__ = (db.UniqueConstraint("baby_id", "user_id"),)

    id = db.Column(db.Integer, primary_key=True)
    baby_id = db.Column(db.Integer, db.ForeignKey("babies.id", ondelete="CASCADE"), nullable=False)
    user_id = db.Column(db.Integer, db.ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    role = db.Column(db.String, nullable=False, default="tutor")  # 'adm' | 'tutor' | 'visualizador'
    title = db.Column(db.String, nullable=True)
    created_at = db.Column(db.DateTime(timezone=True), nullable=False, default=lambda: datetime.now(timezone.utc))

    baby = db.relationship("Baby", back_populates="baby_users")
    user = db.relationship("User")
