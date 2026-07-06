from datetime import datetime, timezone
from db.base import db

class Diaper(db.Model):
    __tablename__ = "diapers"

    id = db.Column(db.Integer, primary_key=True)
    baby_id = db.Column(db.Integer, db.ForeignKey("babies.id", ondelete="CASCADE"), nullable=False)
    changed_at = db.Column(db.DateTime(timezone=True), nullable=False)
    created_at = db.Column(db.DateTime(timezone=True), nullable=False, default=lambda: datetime.now(timezone.utc))

    # V3 — complementação de dados (todos opcionais; type é o campo
    # "estrutural" usado pelo frontend pra marcar o evento como incompleto).
    type = db.Column(db.String, nullable=True)         # urina | fezes | ambos
    consistency = db.Column(db.String, nullable=True)  # liquida | pastosa | solida (só type=fezes|ambos)
    note = db.Column(db.Text, nullable=True)

    baby = db.relationship("Baby", back_populates="diapers")
