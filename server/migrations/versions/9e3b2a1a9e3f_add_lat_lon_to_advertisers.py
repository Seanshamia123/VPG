"""add latitude and longitude to advertisers

Revision ID: 9e3b2a1a9e3f
Revises: 8131032bda82
Create Date: 2025-08-28 00:00:00.000000
"""

from alembic import op
import sqlalchemy as sa

# revision identifiers, used by Alembic.
revision = '9e3b2a1a9e3f'
down_revision = '8131032bda82'
branch_labels = None
depends_on = None


def upgrade():
    with op.batch_alter_table('advertisers') as batch_op:
        batch_op.add_column(sa.Column('latitude', sa.Float(), nullable=True))
        batch_op.add_column(sa.Column('longitude', sa.Float(), nullable=True))


def downgrade():
    with op.batch_alter_table('advertisers') as batch_op:
        batch_op.drop_column('longitude')
        batch_op.drop_column('latitude')

