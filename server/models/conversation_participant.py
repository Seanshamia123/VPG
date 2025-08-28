from database import db

class ConversationParticipant(db.Model):
    __tablename__ = 'conversation_participants'

    id = db.Column(db.Integer, primary_key=True)
    conversation_id = db.Column(db.ForeignKey('conversations.id', ondelete='CASCADE'), nullable=False, index=True)
    participant_type = db.Column(db.String(20), nullable=False)  # 'user' or 'advertiser'
    participant_id = db.Column(db.Integer, nullable=False)

    __table_args__ = (
        db.UniqueConstraint('conversation_id', 'participant_type', 'participant_id', name='uq_conv_participant'),
        db.Index('idx_conv_participant', 'conversation_id', 'participant_type', 'participant_id'),
    )

