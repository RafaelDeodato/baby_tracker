"""compartilhamento de bebes: baby_users, baby_invites, notifications

Revision ID: 5989b87d3b50
Revises: 3b4b59d4481f
Create Date: 2026-07-07 20:56:01.168619

"""
import re
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = '5989b87d3b50'
down_revision: Union[str, None] = '3b4b59d4481f'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Upgrade schema."""
    op.create_table('baby_invites',
    sa.Column('id', sa.Integer(), nullable=False),
    sa.Column('baby_id', sa.Integer(), nullable=False),
    sa.Column('invited_user_id', sa.Integer(), nullable=False),
    sa.Column('invited_by_id', sa.Integer(), nullable=False),
    sa.Column('role', sa.String(), nullable=False),
    sa.Column('title', sa.String(), nullable=True),
    sa.Column('status', sa.String(), nullable=False),
    sa.Column('created_at', sa.DateTime(timezone=True), nullable=False),
    sa.Column('resolved_at', sa.DateTime(timezone=True), nullable=True),
    sa.ForeignKeyConstraint(['baby_id'], ['babies.id'], ondelete='CASCADE'),
    sa.ForeignKeyConstraint(['invited_by_id'], ['users.id'], ondelete='CASCADE'),
    sa.ForeignKeyConstraint(['invited_user_id'], ['users.id'], ondelete='CASCADE'),
    sa.PrimaryKeyConstraint('id')
    )
    op.create_table('baby_users',
    sa.Column('id', sa.Integer(), nullable=False),
    sa.Column('baby_id', sa.Integer(), nullable=False),
    sa.Column('user_id', sa.Integer(), nullable=False),
    sa.Column('role', sa.String(), nullable=False),
    sa.Column('title', sa.String(), nullable=True),
    sa.Column('created_at', sa.DateTime(timezone=True), nullable=False),
    sa.ForeignKeyConstraint(['baby_id'], ['babies.id'], ondelete='CASCADE'),
    sa.ForeignKeyConstraint(['user_id'], ['users.id'], ondelete='CASCADE'),
    sa.PrimaryKeyConstraint('id'),
    sa.UniqueConstraint('baby_id', 'user_id')
    )
    op.create_table('notifications',
    sa.Column('id', sa.Integer(), nullable=False),
    sa.Column('user_id', sa.Integer(), nullable=False),
    sa.Column('type', sa.String(), nullable=False),
    sa.Column('reference_id', sa.Integer(), nullable=True),
    sa.Column('read', sa.Boolean(), nullable=False),
    sa.Column('created_at', sa.DateTime(timezone=True), nullable=False),
    sa.ForeignKeyConstraint(['user_id'], ['users.id'], ondelete='CASCADE'),
    sa.PrimaryKeyConstraint('id')
    )

    conn = op.get_bind()

    # Backfill: bebê existente vira baby_users com role='adm' pro dono atual,
    # antes de remover a coluna babies.user_id.
    conn.execute(sa.text(
        "INSERT INTO baby_users (baby_id, user_id, role, created_at) "
        "SELECT id, user_id, 'adm', now() FROM babies"
    ))

    op.drop_constraint(op.f('babies_user_id_fkey'), 'babies', type_='foreignkey')
    op.drop_column('babies', 'user_id')

    # username: adiciona anulável primeiro, faz backfill a partir do prefixo
    # do e-mail (deduplicado), só depois torna obrigatório e único — não dá
    # pra criar já NOT NULL/UNIQUE com usuários existentes sem valor.
    op.add_column('users', sa.Column('username', sa.String(), nullable=True))

    users = conn.execute(sa.text("SELECT id, email FROM users")).fetchall()
    used_usernames = set()
    for user_id, email in users:
        base = re.sub(r'[^a-z0-9_]', '', email.split('@')[0].lower()) or f"user{user_id}"
        candidate = base
        suffix = 1
        while candidate in used_usernames:
            candidate = f"{base}{suffix}"
            suffix += 1
        used_usernames.add(candidate)
        conn.execute(
            sa.text("UPDATE users SET username = :username WHERE id = :id"),
            {"username": candidate, "id": user_id}
        )

    op.alter_column('users', 'username', nullable=False)
    op.create_unique_constraint(None, 'users', ['username'])


def downgrade() -> None:
    """Downgrade schema."""
    op.drop_constraint(None, 'users', type_='unique')
    op.drop_column('users', 'username')
    op.add_column('babies', sa.Column('user_id', sa.INTEGER(), autoincrement=False, nullable=True))
    op.execute(sa.text(
        "UPDATE babies SET user_id = ("
        "  SELECT user_id FROM baby_users WHERE baby_users.baby_id = babies.id AND baby_users.role = 'adm' LIMIT 1"
        ")"
    ))
    op.alter_column('babies', 'user_id', nullable=False)
    op.create_foreign_key(op.f('babies_user_id_fkey'), 'babies', 'users', ['user_id'], ['id'])
    op.drop_table('notifications')
    op.drop_table('baby_users')
    op.drop_table('baby_invites')
