"""add profile_image_url to users

Revision ID: 7c2a9f1d8b01
Revises: 5a7c1f2b3c4d
Create Date: 2025-08-28 00:20:00.000000
"""

from alembic import op
import sqlalchemy as sa

revision = '7c2a9f1d8b01'
down_revision = '5a7c1f2b3c4d'
branch_labels = None
depends_on = None


def upgrade():
    with op.batch_alter_table('users') as batch_op:
        batch_op.add_column(sa.Column('profile_image_url', sa.String(length=500), nullable=True))


def downgrade():
    with op.batch_alter_table('users') as batch_op:
        batch_op.drop_column('profile_image_url')

