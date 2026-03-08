"""
╔══════════════════════════════════════════════════════════════════════════════╗
║  C.A.R.E — Certificate Verification Engine  v3                             ║
║  Multi-layer AI for printed + handwritten certificates                     ║
║                                                                              ║
║  PIPELINE:                                                                   ║
║   1.  Load  — JPG / PNG / PDF (converts PDF→image at 300 DPI)              ║
║   2.  Enhance — 8 image variants (contrast, adaptive, deskew, CLAHE…)      ║
║   3.  OCR Layer A — EasyOCR   (best for handwriting, cursive, layouts)     ║
║   4.  OCR Layer B — Tesseract (best for printed/typed text)                ║
║   5.  OCR Layer C — Claude Vision API (fallback for hard cases)            ║
║   6.  Name Extraction — 6 strategies (triggers, all-caps, titles, NER…)    ║
║   7.  Fuzzy Matching — 8 metrics (ratio, tokens, initials, phonetic…)      ║
║   8.  Confidence scoring + auto decision                                    ║
║                                                                              ║
║  INSTALL:                                                                    ║
║    pip install easyocr pytesseract opencv-python-headless Pillow            ║
║                pdf2image numpy rapidfuzz anthropic --break-system-packages  ║
║    Linux:   sudo apt-get install tesseract-ocr poppler-utils                ║
║    Windows: https://github.com/UB-Mannheim/tesseract/wiki                  ║
╚══════════════════════════════════════════════════════════════════════════════╝
"""

import cv2
import numpy as np
import re
import os
import base64
import logging
from pathlib import Path
from io import BytesIO
from PIL import Image

from rapidfuzz import fuzz

log = logging.getLogger("cert_verify_v3")
logging.basicConfig(level=logging.INFO)

# ══════════════════════════════════════════════════════════════════════════════
#  LAZY LOADERS
# ══════════════════════════════════════════════════════════════════════════════

_easyocr_reader = None
_tesseract_ok   = None


def get_easyocr():
    global _easyocr_reader
    if _easyocr_reader is None:
        try:
            import easyocr
            _easyocr_reader = easyocr.Reader(
                ['en'], gpu=False, verbose=False,
                detect_network='craft', recog_network='standard')
            log.info("EasyOCR loaded")
        except ImportError:
            log.warning("easyocr not installed — pip install easyocr")
            _easyocr_reader = False
        except Exception as e:
            log.warning(f"EasyOCR failed: {e}")
            _easyocr_reader = False
    return _easyocr_reader if _easyocr_reader else None


def tesseract_available():
    global _tesseract_ok
    if _tesseract_ok is None:
        try:
            import pytesseract
            pytesseract.get_tesseract_version()
            _tesseract_ok = True
            log.info("Tesseract loaded")
        except Exception:
            _tesseract_ok = False
            log.warning("Tesseract not found — install tesseract-ocr")
    return _tesseract_ok


# ══════════════════════════════════════════════════════════════════════════════
#  IMAGE LOADING
# ══════════════════════════════════════════════════════════════════════════════

def load_image(source, filename='') -> np.ndarray:
    """Accept file path, bytes, or BytesIO. Handle JPG/PNG/PDF."""
    ext = Path(filename).suffix.lower() if filename else ''
    if isinstance(source, (str, Path)):
        ext = Path(source).suffix.lower()
    if ext == '.pdf':
        return _load_pdf(source)
    if isinstance(source, (str, Path)):
        img = cv2.imread(str(source))
        return img if img is not None else _pil_load(source)
    data = source.read() if hasattr(source, 'read') else source
    arr = np.frombuffer(data, np.uint8)
    img = cv2.imdecode(arr, cv2.IMREAD_COLOR)
    if img is None:
        img = _pil_load(BytesIO(data))
    return img


def _pil_load(source):
    try:
        pil = Image.open(source).convert('RGB')
        return cv2.cvtColor(np.array(pil), cv2.COLOR_RGB2BGR)
    except Exception:
        return None


def _load_pdf(source):
    try:
        from pdf2image import convert_from_path, convert_from_bytes
        if isinstance(source, (str, Path)):
            pages = convert_from_path(str(source), dpi=300, first_page=1, last_page=1)
        else:
            data = source if isinstance(source, bytes) else source.read()
            pages = convert_from_bytes(data, dpi=300, first_page=1, last_page=1)
        if pages:
            return cv2.cvtColor(np.array(pages[0].convert('RGB')), cv2.COLOR_RGB2BGR)
    except Exception as e:
        log.warning(f"PDF load error: {e}")
    return None


# ══════════════════════════════════════════════════════════════════════════════
#  IMAGE ENHANCEMENT — 8 variants
# ══════════════════════════════════════════════════════════════════════════════

def enhance_image(img: np.ndarray) -> dict:
    gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
    h, w = gray.shape
    v = {}

    # 1. OTSU binarization (standard)
    _, bw = cv2.threshold(gray, 0, 255, cv2.THRESH_BINARY + cv2.THRESH_OTSU)
    v['otsu'] = bw

    # 2. CLAHE — equalizes local contrast, great for photo-certs
    clahe_img = cv2.createCLAHE(clipLimit=2.5, tileGridSize=(8, 8)).apply(gray)
    _, bw = cv2.threshold(clahe_img, 0, 255, cv2.THRESH_BINARY + cv2.THRESH_OTSU)
    v['clahe'] = bw

    # 3. Adaptive threshold — handles uneven lighting, shadows, handwriting
    v['adaptive'] = cv2.adaptiveThreshold(
        gray, 255, cv2.ADAPTIVE_THRESH_GAUSSIAN_C, cv2.THRESH_BINARY, 31, 11)

    # 4. Sharpened — reveals faded ink
    kernel = np.array([[-1,-1,-1],[-1,9,-1],[-1,-1,-1]])
    sharp = cv2.filter2D(gray, -1, kernel)
    _, bw = cv2.threshold(sharp, 0, 255, cv2.THRESH_BINARY + cv2.THRESH_OTSU)
    v['sharpened'] = bw

    # 5. Inverted OTSU — for dark-background / gold certs
    _, bw = cv2.threshold(cv2.bitwise_not(gray), 0, 255,
                          cv2.THRESH_BINARY + cv2.THRESH_OTSU)
    v['inverted'] = bw

    # 6. Morphological clean — remove noise, keep text strokes
    kern = cv2.getStructuringElement(cv2.MORPH_RECT, (2, 2))
    _, bw = cv2.threshold(gray, 0, 255, cv2.THRESH_BINARY + cv2.THRESH_OTSU)
    v['morphed'] = cv2.morphologyEx(bw, cv2.MORPH_CLOSE, kern)

    # 7. Deskewed — corrects rotation from phone photos
    v['deskewed'] = _deskew(gray)

    # 8. Upscaled — for small/low-res images
    if w < 1400:
        scale = 2.5 if w < 500 else (2.0 if w < 800 else 1.5)
        up = cv2.resize(gray, None, fx=scale, fy=scale, interpolation=cv2.INTER_CUBIC)
        _, bw = cv2.threshold(up, 0, 255, cv2.THRESH_BINARY + cv2.THRESH_OTSU)
        v['upscaled'] = bw

    return v


def _deskew(gray: np.ndarray) -> np.ndarray:
    try:
        edges = cv2.Canny(gray, 50, 150, apertureSize=3)
        lines = cv2.HoughLines(edges, 1, np.pi / 180, threshold=100)
        if lines is not None:
            angles = []
            for line in lines[:30]:
                rho, theta = line[0]
                angle = (theta * 180 / np.pi) - 90
                if abs(angle) < 25:
                    angles.append(angle)
            if angles:
                angle = float(np.median(angles))
                if abs(angle) > 0.3:
                    h, w = gray.shape
                    M = cv2.getRotationMatrix2D((w/2, h/2), angle, 1)
                    return cv2.warpAffine(gray, M, (w, h),
                                         flags=cv2.INTER_CUBIC,
                                         borderMode=cv2.BORDER_REPLICATE)
    except Exception:
        pass
    return gray


def _to_b64(img: np.ndarray) -> str:
    _, buf = cv2.imencode('.jpg', img, [cv2.IMWRITE_JPEG_QUALITY, 88])
    return base64.b64encode(buf.tobytes()).decode('utf-8')


# ══════════════════════════════════════════════════════════════════════════════
#  OCR LAYER A — EasyOCR (handwriting-first)
# ══════════════════════════════════════════════════════════════════════════════

def run_easyocr(img_arr: np.ndarray) -> list:
    reader = get_easyocr()
    if reader is None:
        return []
    try:
        results = reader.readtext(img_arr, detail=1, paragraph=False,
                                  width_ths=0.7, mag_ratio=1.5, canvas_size=2560)
        return [{'text': t.strip(), 'confidence': float(c)}
                for _, t, c in results if t.strip()]
    except Exception as e:
        log.warning(f"EasyOCR: {e}")
        return []


# ══════════════════════════════════════════════════════════════════════════════
#  OCR LAYER B — Tesseract (printed text)
# ══════════════════════════════════════════════════════════════════════════════

def run_tesseract(img_arr: np.ndarray, psm: int = 3) -> list:
    if not tesseract_available():
        return []
    try:
        import pytesseract
        data = pytesseract.image_to_data(
            img_arr, output_type=pytesseract.Output.DICT,
            config=f'--psm {psm} --oem 3 -c preserve_interword_spaces=1')
        return [{'text': t.strip(), 'confidence': float(c) / 100.0}
                for t, c in zip(data['text'], data['conf'])
                if t.strip() and float(c) > 15]
    except Exception as e:
        log.warning(f"Tesseract: {e}")
        return []


# ══════════════════════════════════════════════════════════════════════════════
#  OCR LAYER C — Claude Vision API (AI fallback for hard cases)
# ══════════════════════════════════════════════════════════════════════════════

def run_vision_ai(img: np.ndarray, student_name: str) -> dict:
    """
    Uses Claude Vision to read the certificate and extract the recipient name.
    Falls back gracefully if anthropic is not installed or API key not set.
    """
    api_key = os.environ.get('ANTHROPIC_API_KEY', '')
    if not api_key:
        return {}
    try:
        import anthropic
        client  = anthropic.Anthropic(api_key=api_key)
        img_b64 = _to_b64(img)

        prompt = f"""Analyze this certificate image carefully.

Tasks:
1. Read ALL text visible — including any handwritten portions.
2. Find the name of the recipient (the person who received this certificate).
3. Compare it to: "{student_name}"

Respond in EXACTLY this format (no other text):
FULL_TEXT: <every word you can read>
RECIPIENT_NAME: <name on certificate>
MATCH_CONFIDENCE: <0.0 to 1.0>
MATCH_REASON: <one sentence explanation>

Rules:
- Initials like "A. Kumar" count as a match for "Arun Kumar"
- Reversed order "Kumar Arun" counts as match for "Arun Kumar"
- Phonetic variants like "Siva/Shiva", "Mohamed/Muhammad" count as matches
- Give 0.0 if name is totally different or you cannot find any name"""

        response = client.messages.create(
            model="claude-opus-4-5",
            max_tokens=500,
            messages=[{
                "role": "user",
                "content": [
                    {"type": "image",
                     "source": {"type": "base64",
                                "media_type": "image/jpeg",
                                "data": img_b64}},
                    {"type": "text", "text": prompt}
                ]
            }]
        )

        raw = response.content[0].text.strip()
        log.info(f"Vision AI: {raw[:180]}")

        out = {'text': '', 'extracted_name': '', 'confidence': 0.0, 'reason': ''}
        for line in raw.split('\n'):
            if line.startswith('FULL_TEXT:'):
                out['text'] = line[len('FULL_TEXT:'):].strip()
            elif line.startswith('RECIPIENT_NAME:'):
                out['extracted_name'] = line[len('RECIPIENT_NAME:'):].strip()
            elif line.startswith('MATCH_CONFIDENCE:'):
                try:
                    out['confidence'] = float(line[len('MATCH_CONFIDENCE:'):].strip())
                except ValueError:
                    pass
            elif line.startswith('MATCH_REASON:'):
                out['reason'] = line[len('MATCH_REASON:'):].strip()
        return out

    except ImportError:
        log.info("anthropic not installed — Vision AI skipped")
        return {}
    except Exception as e:
        log.warning(f"Vision AI error: {e}")
        return {}


# ══════════════════════════════════════════════════════════════════════════════
#  NAME EXTRACTION — 6 strategies
# ══════════════════════════════════════════════════════════════════════════════

NAME_TRIGGERS = [
    r'certif(?:ied|icate|y|ication)[^.]{0,30}?that\s+(?:mr\.?|ms\.?|mrs\.?|dr\.?|sri\.?|smt\.?)?\s*',
    r'award(?:ed)?\s+to\s+(?:mr\.?|ms\.?|mrs\.?|dr\.?|sri\.?|smt\.?)?\s*',
    r'present(?:ed)?\s+to\s+(?:mr\.?|ms\.?|mrs\.?|dr\.?|sri\.?|smt\.?)?\s*',
    r'conferred\s+(?:upon|on|to)\s+',
    r'in\s+recognition\s+of\s+',
    r'completed\s+by\s+',
    r'achieved\s+by\s+',
    r'participant[:\s]+',
    r'recipient[:\s]+',
    r'student\s*(?:name)?[:\s]+',
    r'name\s*:\s*',
    r'this\s+is\s+to\s+certify\s+that\s+',
    r'we\s+hereby\s+certify\s+that\s+',
    r'honoring\s+',
    r'given\s+to\s+',
    r'belongs\s+to\s+',
]

NOISE_WORDS = {
    'certificate','certify','award','achievement','participation','excellence',
    'completion','presented','awarded','recognize','recognition','college',
    'university','institute','department','school','first','second','third',
    'prize','rank','honor','honours','distinction','congratulations','hereby',
    'successfully','completed','program','course','workshop','seminar','event',
    'competition','contest','organized','conducted','held','dated','january',
    'february','march','april','may','june','july','august','september',
    'october','november','december','date','place','venue','signed','principal',
    'director','chairman','coordinator','incharge','head','this','that','the',
    'and','for','has','have','been','from','our','your','their','given','above',
    'below','register','roll','number','reg','no','technology','engineering',
    'science','arts','management','national','international','annual','technical',
    'cultural','sports','winner','runner','position','level','grade','department',
    'presented','with','having','during','association','society','club','team',
    'signature','authority','registrar','controller','examinations','result',
    'marks','pass','fail','percentage','total','obtained','training','program',
}


def _is_name_token(t: str) -> bool:
    t = t.strip().rstrip('.')
    if len(t) < 2:
        return False
    if t.lower() in NOISE_WORDS:
        return False
    if re.match(r'^[A-Z]\.?$', t):   # initial like "A."
        return True
    if sum(c.isalpha() for c in t) / len(t) < 0.70:
        return False
    return t[0].isupper()


def _clean(raw: str) -> str:
    if not raw:
        return ''
    raw = re.sub(r'[^A-Za-z\s\.]', '', raw)
    tokens = [t for t in raw.split()
              if t.lower() not in NOISE_WORDS and len(t) >= 2]
    if not tokens:
        return ''
    result = []
    for t in tokens:
        result.append(t if re.match(r'^[A-Z]\.$', t) else t.capitalize())
    return ' '.join(result).strip()


def extract_names(text: str) -> list:
    """Returns list of (name, confidence) sorted high→low."""
    seen = {}

    def add(name, conf):
        c = _clean(name)
        if c and 1 <= len(c.split()) <= 6:
            k = c.lower()
            if k not in seen or seen[k][1] < conf:
                seen[k] = (c, conf)

    text_low = text.lower()
    lines    = text.split('\n')

    # 1 — Trigger phrases
    for pattern in NAME_TRIGGERS:
        for m in re.finditer(pattern, text_low, re.IGNORECASE):
            after = text[m.end():m.end() + 150].strip()
            for line in after.split('\n'):
                line = line.strip()
                if len(line) >= 3:
                    candidate = re.split(r'[,\.\n\r;(]', line)[0].strip()
                    add(candidate, 0.92)
                    break

    # 2 — Lines that look entirely like a name
    for line in lines:
        line = line.strip()
        if not line or len(line) > 100:
            continue
        tokens = line.split()
        if 2 <= len(tokens) <= 5:
            if sum(_is_name_token(t) for t in tokens) >= max(1, len(tokens) - 1):
                add(line, 0.78)

    # 3 — Honorific prefix
    title_re = (r'\b(?:Mr\.?|Ms\.?|Mrs\.?|Dr\.?|Sri\.?|Smt\.?|Shri\.?|'
                r'Prof\.?|Er\.?)\s+'
                r'([A-Z][a-z]+(?:\s+[A-Z][a-z]+){0,4})')
    for m in re.finditer(title_re, text):
        add(m.group(1), 0.95)

    # 4 — ALL-CAPS block
    for m in re.finditer(r'\b([A-Z]{2,}(?:\s+[A-Z]{2,}){1,4})\b', text):
        words = m.group(1).split()
        if 2 <= len(words) <= 5:
            if not all(w.lower() in NOISE_WORDS for w in words):
                add(m.group(1).title(), 0.72)

    # 5 — Underline-padded / blank-padded name
    for m in re.finditer(
            r'(?:_{3,}|[-]{3,})\s*([A-Z][a-z]+(?:\s+[A-Z][a-z]+){1,4})\s*(?:_{3,}|[-]{3,})',
            text):
        add(m.group(1), 0.88)

    # 6 — "awarded/presented" + capitalized words
    for m in re.finditer(
            r'(?:is\s+)?(?:awarded|presented|given|conferred)[^A-Z]{0,20}'
            r'([A-Z][a-z]+(?:\s+[A-Z][a-z]+){1,4})',
            text):
        add(m.group(1), 0.90)

    return sorted(seen.values(), key=lambda x: -x[1])


# ══════════════════════════════════════════════════════════════════════════════
#  FUZZY MATCHING — 8 metrics
# ══════════════════════════════════════════════════════════════════════════════

def _soundex(name: str) -> str:
    """Simple phonetic code for Indian name variant matching."""
    n = name.upper()
    groups = {
        'AEIOUHY': '0', 'BFPV': '1', 'CGJKQSXZ': '2',
        'DT': '3', 'L': '4', 'MN': '5', 'R': '6',
    }
    code = ''
    for ch in n:
        for chars, digit in groups.items():
            if ch in chars:
                if not code or code[-1] != digit:
                    code += digit
                break
    return code


def match_name(extracted: str, registered: str) -> float:
    """
    Compare names using 8 metrics. Returns score 0.0–1.0.
    Handles initials, reversed order, OCR errors, phonetics.
    """
    if not extracted or not registered:
        return 0.0
    e = extracted.lower().strip()
    s = registered.lower().strip()
    if e == s:
        return 1.0

    scores = [
        fuzz.ratio(e, s) / 100.0,
        fuzz.token_sort_ratio(e, s) / 100.0,   # order invariant
        fuzz.token_set_ratio(e, s) / 100.0,    # subset
        fuzz.partial_ratio(e, s) / 100.0 * 0.85,
    ]

    ep = e.split()
    sp = s.split()

    # Surname / first name exact match bonus
    if ep and sp:
        if ep[-1] == sp[-1]: scores.append(0.83)
        if ep[0]  == sp[0]:  scores.append(0.79)

    # Initials expansion
    def init_score(short, full):
        if len(short) != len(full): return 0.0
        hits = sum(
            1 if a == b else (0.9 if len(a.rstrip('.')) == 1 and b.startswith(a.rstrip('.')) else 0)
            for a, b in zip(short, full)
        )
        return hits / len(full)

    scores += [init_score(ep, sp), init_score(sp, ep)]

    # All-initials match e.g. "AKS" ↔ "Arun Kumar Sharma"
    ei = ''.join(p[0] for p in ep if p)
    si = ''.join(p[0] for p in sp if p)
    if len(ei) >= 2 and len(si) >= 2:
        if ei == si:               scores.append(0.80)
        elif ei in si or si in ei: scores.append(0.65)

    # Phonetic similarity (handles Siva/Shiva, Mohamed/Muhammad)
    ph_score = fuzz.ratio(_soundex(e), _soundex(s)) / 100.0
    scores.append(ph_score * 0.72)

    best = max(scores)
    avg3 = sum(sorted(scores, reverse=True)[:3]) / 3
    return round(min(best * 0.60 + avg3 * 0.40, 1.0), 4)


# ══════════════════════════════════════════════════════════════════════════════
#  MAIN FUNCTION
# ══════════════════════════════════════════════════════════════════════════════

def verify_certificate(
    source,
    student_name: str,
    filename: str = '',
    threshold: float = 0.62,
    use_vision_ai: bool = True,
) -> dict:
    """
    Full AI pipeline verification.

    Returns:
        status:          'verified' | 'manual_review' | 'rejected'
        verified:        bool
        confidence:      float 0.0–1.0
        match_score:     float
        extracted_name:  str
        all_candidates:  list of (name, conf)
        ocr_text:        str
        vision_ai_used:  bool
        reason:          str
    """
    result = dict(status='manual_review', verified=False, confidence=0.0,
                  match_score=0.0, extracted_name='', all_candidates=[],
                  ocr_text='', vision_ai_used=False, reason='')

    # Load
    try:
        img = load_image(source, filename)
    except Exception as e:
        result['reason'] = f'Load error: {e}'
        return result
    if img is None or img.size == 0:
        result['reason'] = 'Empty or corrupt image'
        return result

    # Enhance
    variants = enhance_image(img)
    gray     = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)

    # OCR A — EasyOCR on gray, deskewed, upscaled
    tokens = []
    for vn in ['upscaled', 'deskewed']:
        if vn in variants: tokens += run_easyocr(variants[vn])
    tokens += run_easyocr(gray)

    # OCR B — Tesseract on multiple variants
    for vn, psm in [('adaptive',3),('clahe',3),('morphed',3),
                    ('otsu',3),('sharpened',6)]:
        if vn in variants: tokens += run_tesseract(variants[vn], psm)

    full_text = '\n'.join(t['text'] for t in tokens if t.get('text'))
    result['ocr_text'] = full_text[:600]

    # Extract + match
    candidates = extract_names(full_text)
    result['all_candidates'] = [(n, round(c, 3)) for n, c in candidates[:8]]

    best_name, best_score, best_conf = '', 0.0, 0.0
    for cname, cconf in candidates:
        sc = match_name(cname, student_name)
        combined = sc * 0.65 + cconf * 0.35
        if combined > best_conf:
            best_conf  = combined
            best_score = sc
            best_name  = cname

    result.update(extracted_name=best_name,
                  match_score=round(best_score, 4),
                  confidence=round(best_conf, 4))

    # Vision AI fallback — trigger when no name OR moderate match
    needs_vision = (
        use_vision_ai
        and (not best_name or 0.28 < best_score < 0.76)
        and bool(os.environ.get('ANTHROPIC_API_KEY'))
    )
    if needs_vision:
        log.info(f"Vision AI fallback for: {student_name}")
        vision = run_vision_ai(img, student_name)
        if vision:
            result['vision_ai_used'] = True
            vname = vision.get('extracted_name', '')
            vconf = float(vision.get('confidence', 0.0))
            if vname:
                vscore    = match_name(vname, student_name)
                vcombined = max(vscore, vconf)
                if vcombined > best_conf:
                    best_name, best_score, best_conf = vname, vscore, vcombined
                    result.update(extracted_name=best_name,
                                  match_score=round(best_score, 4),
                                  confidence=round(best_conf, 4))
            # Mine vision's full_text too
            if vision.get('text'):
                for vn, vc in extract_names(vision['text'])[:5]:
                    vs = match_name(vn, student_name)
                    comb = vs * 0.65 + vc * 0.35
                    if comb > best_conf:
                        best_name, best_score, best_conf = vn, vs, comb
                        result.update(extracted_name=best_name,
                                      match_score=round(best_score, 4),
                                      confidence=round(best_conf, 4))

    # Decision
    s = best_score
    if s >= 0.88:
        result.update(verified=True, status='verified',
                      reason=f'Strong match ({s:.0%}): "{best_name}" ≈ "{student_name}"')
    elif s >= threshold:
        result.update(verified=True, status='verified',
                      reason=f'Good match ({s:.0%}): "{best_name}" accepted')
    elif s >= 0.40:
        result.update(verified=False, status='manual_review',
                      reason=f'Partial match ({s:.0%}): "{best_name}" — staff review needed')
    elif s > 0.0:
        result.update(verified=False, status='rejected',
                      reason=f'Weak match ({s:.0%}): "{best_name}" ≠ "{student_name}"')
    else:
        result.update(verified=False, status='manual_review',
                      reason='Could not extract any name — manual review required')

    log.info(f"CERT | {student_name} | extracted={best_name} | "
             f"score={best_score:.2f} | {result['status']}")
    return result


# ══════════════════════════════════════════════════════════════════════════════
#  FLASK HELPER
# ══════════════════════════════════════════════════════════════════════════════

def verify_certificate_upload(flask_file, student_name: str) -> dict:
    """
    Use in app.py:
        from certificate_verify import verify_certificate_upload
        result = verify_certificate_upload(request.files['file'], user['name'])
    """
    file_bytes = flask_file.read()
    flask_file.seek(0)
    return verify_certificate(file_bytes, student_name,
                               filename=flask_file.filename, use_vision_ai=True)


# ══════════════════════════════════════════════════════════════════════════════
#  CLI TEST
# ══════════════════════════════════════════════════════════════════════════════

if __name__ == '__main__':
    import sys
    if len(sys.argv) < 3:
        print('Usage: python certificate_verify.py <image> "Student Name"')
        sys.exit(1)

    res = verify_certificate(sys.argv[1], sys.argv[2])
    print(f"\n{'═'*55}")
    print(f"STATUS:         {res['status'].upper()}")
    print(f"VERIFIED:       {'✓ YES' if res['verified'] else '✗ NO'}")
    print(f"CONFIDENCE:     {res['confidence']:.1%}")
    print(f"MATCH SCORE:    {res['match_score']:.1%}")
    print(f"EXTRACTED NAME: {res['extracted_name']}")
    print(f"VISION AI:      {'Yes' if res['vision_ai_used'] else 'No'}")
    print(f"REASON:         {res['reason']}")
    print(f"{'═'*55}")
    print("CANDIDATES:")
    for n, c in res['all_candidates'][:6]:
        ms = match_name(n, sys.argv[2])
        print(f"  {n:<35} extract={c:.0%}  match={ms:.0%}")
    print(f"\nOCR:\n{res['ocr_text'][:400]}")