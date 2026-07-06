from datetime import datetime, timezone
from db.base import db

class Nap(db.Model):
    __tablename__ = "naps"

    id = db.Column(db.Integer, primary_key=True)
    baby_id = db.Column(db.Integer, db.ForeignKey("babies.id", ondelete="CASCADE"), nullable=False)
    started_at = db.Column(db.DateTime(timezone=True), nullable=False)
    ended_at = db.Column(db.DateTime(timezone=True), nullable=True)
    created_at = db.Column(db.DateTime(timezone=True), nullable=False, default=lambda: datetime.now(timezone.utc))

    # V3 — complementação de dados (todos opcionais; location é o campo
    # "estrutural" usado pelo frontend pra marcar o evento como incompleto).
    location = db.Column(db.String, nullable=True)          # berco | colo | carrinho | cama_dos_pais | carro
    light_environment = db.Column(db.String, nullable=True) # claro | escuro
    white_noise = db.Column(db.Boolean, nullable=True)
    note = db.Column(db.Text, nullable=True)

    baby = db.relationship("Baby", back_populates="naps")

    @property
    def duration_minutes(self):
        if self.ended_at is None:
            return None
        delta = self.ended_at - self.started_at
        return round(delta.total_seconds() / 60)
