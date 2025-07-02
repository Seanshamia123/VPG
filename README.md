# VPG

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.



# VPG Django Backend

This is the backend for the **VPG Project**, built with Django and MySQL. It includes user registration with custom fields (name, email, number, profile picture, location, gender), and a shared superuser for development/admin purposes.

---

## 🔧 Requirements

Before getting started, ensure the following dependencies are installed:

### Python & Packages
- Python 3.8+
- Virtualenv
- Django
- mysqlclient

### System
- MySQL Server
- MySQL Workbench (optional GUI)
- Ubuntu 22.04+

---

## 🚀 Getting Started

### 1. Clone the Repository
```bash
git clone https://github.com/yourusername/VPG.git
cd VPG/server/VPGServer
```

### 2. Create and Activate a Virtual Environment
```bash
python3 -m venv venv
source venv/bin/activate
```

### 3. Install Python Dependencies
Ensure your `requirements.txt` includes:
```text
Django>=4.2
mysqlclient
```

Then run:
```bash
pip install -r requirements.txt
```

### 4. Configure MySQL
Ensure MySQL is running. You can install and manage MySQL using:
```bash
sudo apt install mysql-server
sudo systemctl start mysql
```

Create a database and user:
```sql
CREATE DATABASE VPGdb;
CREATE USER 'vpg_user'@'localhost' IDENTIFIED BY 'vipgalz321';
GRANT ALL PRIVILEGES ON VPGdb.* TO 'vpg_user'@'localhost';
FLUSH PRIVILEGES;
```

### 5. Update settings.py
Set your database configuration:
```python
DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.mysql',
        'NAME': 'VPGdb',
        'USER': 'vpg_user',
        'PASSWORD': 'vipgalz321',
        'HOST': 'localhost',
        'PORT': '3306',
    }
}
```

Also add your app to `INSTALLED_APPS`.

### 6. Run Migrations
Run initial migrations:
```bash
python manage.py makemigrations
python manage.py migrate
```

### 7. Create Superuser (Optional)
Create an admin user for accessing Django admin:
```bash
python manage.py createsuperuser
```

### 8. Start the Development Server
```bash
python manage.py runserver
```

The server will be available at `http://127.0.0.1:8000/`

---

## 📁 Project Structure

```
VPG/
├── server/
│   └── VPGServer/
│       ├── manage.py
│       ├── requirements.txt
│       ├── venv/
│       └── [Django project files]
└── README.md
```

---

## 🛠️ Features

- **User Registration**: Custom user model with fields for name, email, phone number, profile picture, location, and gender
- **MySQL Database**: Configured with MySQL backend
- **Admin Interface**: Django admin panel for user management
- **Development Ready**: Shared superuser setup for development and admin purposes

---

## 🔧 Troubleshooting

### MySQL Connection Issues
If you encounter MySQL connection errors:
1. Ensure MySQL service is running: `sudo systemctl status mysql`
2. Check database credentials in `settings.py`
3. Verify the database and user exist in MySQL

### Virtual Environment Issues
If virtual environment activation fails:
```bash
# On Windows
venv\Scripts\activate

# On macOS/Linux
source venv/bin/activate
```

### Migration Errors
If migrations fail:
```bash
# Reset migrations (use with caution)
python manage.py migrate --fake-initial
```

---


---
