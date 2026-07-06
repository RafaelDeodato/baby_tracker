from datetime import datetime, timezone
from db.base import db

class Feeding(db.Model):
    __tablename__ = "feedings"

    id = db.Column(db.Integer, primary_key=True)
    baby_id = db.Column(db.Integer, db.ForeignKey("babies.id", ondelete="CASCADE"), nullable=False)
    started_at = db.Column(db.DateTime(timezone=True), nullable=False)
    ended_at = db.Column(db.DateTime(timezone=True), nullable=True)
    created_at = db.Column(db.DateTime(timezone=True), nullable=False, default=lambda: datetime.now(timezone.utc))

    # V3 — complementação de dados (todos opcionais; type é o campo
    # "estrutural" usado pelo frontend pra marcar o evento como incompleto).
    type = db.Column(db.String, nullable=True)          # peito | formula | ordenhado
    side = db.Column(db.String, nullable=True)           # esquerdo | direito | ambos (só type=peito)
    volume_ml = db.Column(db.Integer, nullable=True)     # só type=formula|ordenhado
    note = db.Column(db.Text, nullable=True)

    baby = db.relationship("Baby", back_populates="feedings")

    @property
    def duration_minutes(self):
        if self.ended_at is None:
            return None
        delta = self.ended_at - self.started_at
        return round(delta.total_seconds() / 60)
