from database import db


class PostLike(db.Model):
    __tablename__ = 'post_likes'

    id = db.Column(db.Integer, primary_key=True)
    post_id = db.Column(db.ForeignKey('posts.id', ondelete='CASCADE'), nullable=False, index=True)
    user_id = db.Column(db.ForeignKey('users.id', ondelete='CASCADE'), nullable=False, index=True)
    created_at = db.Column(db.TIMESTAMP, default=db.func.current_timestamp())

    __table_args__ = (
        db.UniqueConstraint('post_id', 'user_id', name='uq_post_like_post_user'),
    )

