from flask import Blueprint
from app.api.v1.auth import auth_bp
from app.api.v1.babies import babies_bp
from app.api.v1.feedings import feedings_bp
from app.api.v1.naps import naps_bp
from app.api.v1.diapers import diapers_bp
from app.api.v1.users import users_bp
from app.api.v1.invites import invites_bp
from app.api.v1.notifications import notifications_bp

v1_bp = Blueprint("v1", __name__)

v1_bp.register_blueprint(auth_bp, url_prefix="/auth")
v1_bp.register_blueprint(babies_bp, url_prefix="/babies")
v1_bp.register_blueprint(feedings_bp)
v1_bp.register_blueprint(naps_bp)
v1_bp.register_blueprint(diapers_bp)
v1_bp.register_blueprint(users_bp, url_prefix="/users")
v1_bp.register_blueprint(invites_bp)
v1_bp.register_blueprint(notifications_bp)
