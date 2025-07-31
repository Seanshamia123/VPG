from datetime import datetime
from uuid import UUID
import uuid
from database import db
class UserBlock(db.Model):
    __tablename__ = 'user_blocks'
    id = db.Column(db.Integer, primary_key=True)
    blocker_id = db.Column(db.ForeignKey('users.id', ondelete='CASCADE'), nullable=False)
    blocked_id = db.Column(db.ForeignKey('users.id', ondelete='CASCADE'), nullable=False)
    created_at = db.Column(db.TIMESTAMP, default=db.func.current_timestamp())
    __table_args__ = (db.UniqueConstraint('blocker_id', 'blocked_id', name='uq_blocker_blocked'),)
