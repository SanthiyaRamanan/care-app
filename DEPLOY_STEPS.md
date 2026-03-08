# 🚀 CARE — Railway + GitHub Deployment Guide
## Step-by-step from zero to live

---

## STEP 1 — Prepare your local project

### 1.1 Update app.py config
Open `app.py` and replace your database/secret config block with the code in `app_config_patch.py`.
This makes your app read credentials from environment variables instead of hardcoded values.

### 1.2 Copy deployment files into your project root
Copy these files from this zip into your `care_final/` folder:
```
.gitignore
.env.example
requirements.txt
Procfile
railway.toml
README.md
```

### 1.3 Create your local .env (for testing only — never commit!)
```bash
cp .env.example .env
```
Then open `.env` and fill in your LOCAL MySQL credentials.

### 1.4 Test locally first
```bash
pip install -r requirements.txt
python app.py
```
Make sure it works at http://localhost:5000 before pushing.

---

## STEP 2 — Push to GitHub

### 2.1 Initialize Git (if not done yet)
```bash
cd care_final
git init
git add .
git commit -m "Initial commit — CARE app"
```

### 2.2 Create a new repo on GitHub
1. Go to https://github.com/new
2. Name it `care-app` (or anything you like)
3. Set it to **Public** or **Private**
4. Do NOT add README/gitignore (you already have them)
5. Click **Create repository**

### 2.3 Push your code
```bash
git remote add origin https://github.com/YOUR_USERNAME/care-app.git
git branch -M main
git push -u origin main
```

---

## STEP 3 — Set up Railway

### 3.1 Create Railway account
Go to https://railway.app → Sign up with GitHub (easiest).

### 3.2 Create new project
1. Click **New Project**
2. Select **Deploy from GitHub repo**
3. Authorize Railway to access your GitHub
4. Choose your `care-app` repo
5. Railway will detect it's a Python app and start building ✓

### 3.3 Add MySQL database
1. Inside your Railway project, click **+ New**
2. Select **Database → MySQL**
3. Wait ~30 seconds for it to provision

### 3.4 Get your MySQL credentials
1. Click on the MySQL service → **Connect** tab
2. You'll see: Host, Port, User, Password, Database name
3. Copy these — you'll need them in the next step

---

## STEP 4 — Set Environment Variables on Railway

1. Click on your **Flask app** service (not MySQL)
2. Go to the **Variables** tab
3. Add these one by one:

| Variable | Value |
|----------|-------|
| `SECRET_KEY` | any random string e.g. `care2024superSecret!xK9` |
| `MYSQL_HOST` | paste from Railway MySQL Connect tab |
| `MYSQL_PORT` | `3306` |
| `MYSQL_USER` | paste from Railway MySQL Connect tab |
| `MYSQL_PASSWORD` | paste from Railway MySQL Connect tab |
| `MYSQL_DB` | `care_db` |
| `FLASK_ENV` | `production` |
| `FLASK_DEBUG` | `0` |

4. Railway will auto-redeploy after you save variables ✓

---

## STEP 5 — Import your database

### 5.1 Connect MySQL Workbench to Railway MySQL
1. Open MySQL Workbench
2. Click **+** to add new connection
3. Fill in:
   - **Hostname**: Railway MySQL host
   - **Port**: Railway MySQL port (usually 3306 or a custom port)
   - **Username**: root (or Railway user)
   - **Password**: Railway MySQL password
4. Test connection → Connect

### 5.2 Create database and import schema
In MySQL Workbench:
```sql
CREATE DATABASE IF NOT EXISTS care_db;
USE care_db;
```
Then run your SQL schema file (all your CREATE TABLE statements + seed data).

---

## STEP 6 — Get your live URL 🎉

1. Go back to Railway → your Flask service
2. Click **Settings → Networking → Generate Domain**
3. You'll get a URL like `https://care-app-production.up.railway.app`
4. Share this with your users!

---

## STEP 7 — Future deployments (automatic!)

Every time you push to GitHub:
```bash
git add .
git commit -m "Fixed something"
git push
```
Railway automatically detects the push and redeploys. No manual steps needed.

---

## ⚠️ Common Issues

| Problem | Fix |
|---------|-----|
| `ModuleNotFoundError` | Check `requirements.txt` has all your packages |
| `Access denied for MySQL` | Double-check MYSQL_PASSWORD variable on Railway |
| `Application failed to respond` | Check Railway logs — likely a Python error |
| Static files not loading | Make sure `static/` folder is committed to GitHub |
| Uploads not persisting | Railway has ephemeral storage — use Cloudinary or S3 for user uploads |

---

## 📌 Important Note on File Uploads

Railway's filesystem is **ephemeral** — uploaded files (profile pics, certificates) will be deleted on redeploy.
For production, use a cloud storage service:
- **Cloudinary** (free tier, easy for images)
- **AWS S3** or **Backblaze B2**

This is only needed if students upload files. Static assets (CSS/JS/images in your repo) are fine.
