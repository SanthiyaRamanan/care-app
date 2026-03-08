import os
from dotenv import load_dotenv

# Loads .env file when running locally
# On Railway, env vars are set directly in the dashboard — load_dotenv() is ignored there
load_dotenv()

class Config:

    # ── Flask ──
    SECRET_KEY = os.environ.get('SECRET_KEY', 'care_dev_key_change_in_production')

    # ── MySQL ──
    # Locally:  reads from your .env file
    # Railway:  reads from Railway environment variables dashboard
    MYSQL_HOST        = os.environ.get('MYSQL_HOST', 'localhost')
    MYSQL_PORT        = int(os.environ.get('MYSQL_PORT', 3306))
    MYSQL_USER        = os.environ.get('MYSQL_USER', 'root')
    MYSQL_PASSWORD    = os.environ.get('MYSQL_PASSWORD', '')
    MYSQL_DB          = os.environ.get('MYSQL_DB', 'care')
    MYSQL_CURSORCLASS = 'DictCursor'

    # ── File uploads ──
    UPLOAD_FOLDER      = os.environ.get('UPLOAD_FOLDER', 'static/uploads')
    MAX_CONTENT_LENGTH = 10 * 1024 * 1024   # 10 MB

    # ── Stars config ──
    STARS = {
        # Student actions
        'assignment_ontime':  5,
        'assignment_late':    -3,
        'quiz_attempt':       3,
        'attendance_present': 2,
        'result_above75':     15,
        'result_above60':     10,
        'result_above40':     5,
        'project_add':        10,
        'seminar_add':        8,
        # Certificates
        'certificate_workshop_attended':  10,
        'certificate_workshop_conducted': 12,
        'certificate_sports':             12,
        'certificate_inter_college':      15,
        'certificate_intra_college':      10,
        'certificate_seminar':            8,
        'certificate_club_event':         8,
        'certificate_other':              5,
        # Staff actions
        'staff_attendance_session': 1,
        'staff_assignment_post':    3,
        'research_published':       20,
        'research_presented':       15,
    }
