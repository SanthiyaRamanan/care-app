# 🎮 C.A.R.E — Campus Achievement & Recognition Engine

A gamified academic tracking platform for college students, staff, and admins.
Students earn **streak stars** for attendance, assignments, certificates, and more — leveling up and competing on a leaderboard.

---

## ✨ Features

- 🎯 **Gamified Star System** — earn stars for every academic activity
- 🏆 **Leaderboard** — Gold / Silver / Bronze tiers for top 5 students
- 📊 **CAT Marks & Results** — staff enter grades, students view progress
- 📅 **Attendance Tracking** — period-wise, class-wise
- 📜 **Certificate Verification** — AI-assisted verification by staff/CC
- 📝 **Assignments & Quizzes** — create, submit, and grade
- 📄 **Auto Resume Generator** — PDF resume from student activity data
- 👑 **Admin Panel** — manage staff, timetable, subjects, classes
- 📱 **Mobile-first UI** — hamburger side drawer, responsive design

---

## 🛠️ Tech Stack

| Layer | Tech |
|-------|------|
| Backend | Python / Flask |
| Database | MySQL |
| Frontend | Jinja2 + Vanilla JS + CSS |
| Hosting | Railway |
| Fonts | Orbitron, Rajdhani, Share Tech Mono |

---

## 🚀 Deploy on Railway

### 1. Fork / Clone this repo
```bash
git clone https://github.com/YOUR_USERNAME/care-app.git
cd care-app
```

### 2. Create a Railway project
1. Go to [railway.app](https://railway.app) → **New Project**
2. Select **Deploy from GitHub repo** → choose this repo
3. Add a **MySQL** database plugin inside Railway

### 3. Set Environment Variables on Railway
In your Railway project → **Variables** tab, add:

```
SECRET_KEY         = (generate a random string)
MYSQL_HOST         = (from Railway MySQL → Connect tab)
MYSQL_PORT         = 3306
MYSQL_USER         = root
MYSQL_PASSWORD     = (from Railway MySQL)
MYSQL_DB           = care_db
```

### 4. Import your database
1. Open **MySQL Workbench**
2. Connect using Railway's MySQL credentials
3. Run your SQL schema/seed file to create tables

### 5. Done! 🎉
Railway auto-deploys on every `git push`.

---

## 💻 Local Development

```bash
# 1. Clone repo
git clone https://github.com/YOUR_USERNAME/care-app.git
cd care-app

# 2. Create virtual environment
python -m venv venv
source venv/bin/activate      # Mac/Linux
venv\Scripts\activate         # Windows

# 3. Install dependencies
pip install -r requirements.txt

# 4. Create .env file
cp .env.example .env
# Edit .env with your local MySQL credentials

# 5. Run
python app.py
```

---

## 📁 Project Structure

```
care_final/
├── app.py                  # Main Flask application
├── requirements.txt        # Python dependencies
├── Procfile                # Railway/Gunicorn start command
├── railway.toml            # Railway config
├── .env.example            # Environment variable template
├── .gitignore
├── static/
│   ├── css/
│   ├── js/
│   └── uploads/            # User uploaded files (gitignored)
└── templates/
    ├── base.html           # Base layout with sidebar + mobile drawer
    ├── auth/               # login.html, register.html
    ├── student/            # dashboard, results, leaderboard, etc.
    ├── staff/              # attendance, marks, quiz, etc.
    └── admin/              # timetable, subjects, class view, etc.
```

---

## 👥 Roles

| Role | Access |
|------|--------|
| `student` | Dashboard, results, certificates, leaderboard |
| `staff` | Attendance, CAT marks, quiz, assignments |
| `admin` | Full access — staff, timetable, subjects, classes |
| `library` | Library dashboard |

---

## 📄 License

MIT — free to use and modify.
