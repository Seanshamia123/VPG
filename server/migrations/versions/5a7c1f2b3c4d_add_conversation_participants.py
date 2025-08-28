"""add conversation participants table

Revision ID: 5a7c1f2b3c4d
Revises: 9e3b2a1a9e3f
Create Date: 2025-08-28 00:10:00.000000
"""

from alembic import op
import sqlalchemy as sa

revision = '5a7c1f2b3c4d'
down_revision = '9e3b2a1a9e3f'
branch_labels = None
depends_on = None


def upgrade():
    op.create_table(
        'conversation_participants',
        sa.Column('id', sa.Integer(), primary_key=True),
        sa.Column('conversation_id', sa.Integer(), sa.ForeignKey('conversations.id', ondelete='CASCADE'), nullable=False),
        sa.Column('participant_type', sa.String(length=20), nullable=False),
        sa.Column('participant_id', sa.Integer(), nullable=False),
    )
    op.create_unique_constraint('uq_conv_participant', 'conversation_participants', ['conversation_id', 'participant_type', 'participant_id'])
    op.create_index('idx_conv_participant', 'conversation_participants', ['conversation_id', 'participant_type', 'participant_id'])


def downgrade():
    op.drop_index('idx_conv_participant', table_name='conversation_participants')
    op.drop_constraint('uq_conv_participant', 'conversation_participants', type_='unique')
    op.drop_table('conversation_participants')

