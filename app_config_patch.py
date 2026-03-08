# ══════════════════════════════════════════════════════════
#  CARE — app.py changes needed for Railway deployment
#  Paste these at the TOP of your app.py (replace your
#  existing config block with this one)
# ══════════════════════════════════════════════════════════

import os
from dotenv import load_dotenv

# Load .env file locally (ignored on Railway — Railway uses env vars directly)
load_dotenv()

app = Flask(__name__)

# ── Secret Key ──
app.secret_key = os.environ.get('SECRET_KEY', 'fallback-dev-key-change-this')

# ── MySQL config from environment variables ──
app.config['MYSQL_HOST']     = os.environ.get('MYSQL_HOST', 'localhost')
app.config['MYSQL_PORT']     = int(os.environ.get('MYSQL_PORT', 3306))
app.config['MYSQL_USER']     = os.environ.get('MYSQL_USER', 'root')
app.config['MYSQL_PASSWORD'] = os.environ.get('MYSQL_PASSWORD', '')
app.config['MYSQL_DB']       = os.environ.get('MYSQL_DB', 'care_db')
app.config['MYSQL_CURSORCLASS'] = 'DictCursor'

# ── Upload folder ──
UPLOAD_FOLDER = os.environ.get('UPLOAD_FOLDER', 'static/uploads')
app.config['UPLOAD_FOLDER'] = UPLOAD_FOLDER
os.makedirs(UPLOAD_FOLDER, exist_ok=True)
