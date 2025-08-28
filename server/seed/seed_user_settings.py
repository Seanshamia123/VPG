from models.user import User
from models.user_settings import UserSetting  # adjust import path if needed
from database import db
from datetime import datetime
import random

def seed_user_settings():
    """Seeds the user_settings table with sample data for each user."""
    print("Seeding User Settings...")

    # Weighted choices for more realistic defaults
    languages = [
        ("en", 70),  # English default
        ("sw", 25),  # Kiswahili
        ("fr", 5),   # Some French users
    ]

    created_count = 0
    skipped_count = 0

    # Iterate through all users and ensure each has a settings row
    users = User.query.all()

    for user in users:
        # Skip if settings already exist
        existing = UserSetting.query.filter_by(user_id=user.id).first()
        if existing:
            skipped_count += 1
            continue

        # Randomized-but-reasonable defaults
        notification_enabled = random.choices([True, False], weights=[85, 15])[0]
        dark_mode_enabled = random.choices([True, False], weights=[30, 70])[0]
        show_online_status = random.choices([True, False], weights=[80, 20])[0]
        read_receipts = random.choices([True, False], weights=[75, 25])[0]
        selected_language = random.choices(
            [l for (l, _) in languages],
            weights=[w for (_, w) in languages]
        )[0]
        selected_theme = "dark" if dark_mode_enabled else "light"

        # Prefer aligning timestamps with the user's created_at when present
        created_at = getattr(user, "created_at", None) or datetime.utcnow()

        # Opinionated overrides for known demo users
        if getattr(user, "username", "") == "admin":
            notification_enabled = True
            dark_mode_enabled = True
            selected_theme = "dark"
            selected_language = "en"
        elif getattr(user, "username", "") == "testuser":
            selected_language = "en"

        settings = UserSetting(
            user_id=user.id,
            notification_enabled=notification_enabled,
            dark_mode_enabled=dark_mode_enabled,
            show_online_status=show_online_status,
            read_receipts=read_receipts,
            selected_language=selected_language,
            selected_theme=selected_theme,
            created_at=created_at,
            updated_at=created_at,
        )

        db.session.add(settings)
        created_count += 1

    try:
        db.session.commit()
        print(f"Successfully seeded user_settings for {created_count} users! Skipped {skipped_count} (already had settings).")
    except Exception as e:
        db.session.rollback()
        print(f"Error seeding user_settings: {str(e)}")
