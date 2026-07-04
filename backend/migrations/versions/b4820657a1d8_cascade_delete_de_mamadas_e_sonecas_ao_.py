"""cascade delete de mamadas e sonecas ao excluir bebe

Revision ID: b4820657a1d8
Revises: b0ba1cece5d9
Create Date: 2026-07-04 15:44:12.864981

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = 'b4820657a1d8'
down_revision: Union[str, None] = 'b0ba1cece5d9'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Upgrade schema."""
    op.drop_constraint('feedings_baby_id_fkey', 'feedings', type_='foreignkey')
    op.create_foreign_key(
        'feedings_baby_id_fkey', 'feedings', 'babies', ['baby_id'], ['id'], ondelete='CASCADE'
    )

    op.drop_constraint('naps_baby_id_fkey', 'naps', type_='foreignkey')
    op.create_foreign_key(
        'naps_baby_id_fkey', 'naps', 'babies', ['baby_id'], ['id'], ondelete='CASCADE'
    )


def downgrade() -> None:
    """Downgrade schema."""
    op.drop_constraint('naps_baby_id_fkey', 'naps', type_='foreignkey')
    op.create_foreign_key('naps_baby_id_fkey', 'naps', 'babies', ['baby_id'], ['id'])

    op.drop_constraint('feedings_baby_id_fkey', 'feedings', type_='foreignkey')
    op.create_foreign_key('feedings_baby_id_fkey', 'feedings', 'babies', ['baby_id'], ['id'])
