#!/usr/bin/env bash
# ============================================================
# جمعية حقّنا - HAQQUNA
# سكربت التثبيت والتشغيل (يثبّت كل شي ثم يشغّل السيرفر)
# ============================================================
#
# الاستخدام:
#   ./run.sh                  - تشغيل عادي (ينشئ venv، يثبت، يشغل)
#   PORT=9000 ./run.sh        - تشغيل على منفذ مختلف
#   HOST=127.0.0.1 ./run.sh   - تقييد الوصول للجهاز فقط
#   SKIP_DEPS=1 ./run.sh      - تخطّي تثبيت الحزم
#   SKIP_SEED=1 ./run.sh      - تخطّي بذر البيانات المرجعية
#   NO_VENV=1 ./run.sh        - عدم استخدام بيئة افتراضية
#   ./run.sh --help           - عرض المساعدة
# ============================================================

set -e
cd "$(dirname "$0")"

# ---- ألوان الإخراج ----
if [ -t 1 ]; then
    GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'
    RED='\033[0;31m'; CYAN='\033[0;36m'; BOLD='\033[1m'; NC='\033[0m'
else
    GREEN=''; YELLOW=''; BLUE=''; RED=''; CYAN=''; BOLD=''; NC=''
fi

step()   { printf "\n${BLUE}━━━ %s ━━━${NC}\n" "$1"; }
ok()     { printf "${GREEN}✓${NC} %s\n" "$1"; }
warn()   { printf "${YELLOW}⚠${NC} %s\n" "$1"; }
err()    { printf "${RED}✗${NC} %s\n" "$1"; }
info()   { printf "${CYAN}ℹ${NC} %s\n" "$1"; }

# ---- معاملات الإعداد ----
PORT="${PORT:-8000}"
HOST="${HOST:-0.0.0.0}"
VENV_DIR="${VENV_DIR:-.venv}"

# ---- المساعدة ----
if [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
    cat <<EOF
${BOLD}جمعية حقّنا - HAQQUNA - سكربت التشغيل${NC}

الاستخدام:
  ./run.sh                  تثبيت كامل + تشغيل
  ./run.sh --help           عرض هذه الرسالة

متغيرات البيئة:
  PORT=8000                 منفذ السيرفر (افتراضي: 8000)
  HOST=0.0.0.0              عنوان الاستماع
  SKIP_DEPS=1               تخطّي تثبيت الحزم
  SKIP_SEED=1               تخطّي بذر البيانات المرجعية
  NO_VENV=1                 عدم استخدام بيئة افتراضية
  ADMIN_PASSWORD=...        كلمة مرور المسؤول (افتراضي: haqquna2026)

أمثلة:
  PORT=9000 ./run.sh
  HOST=127.0.0.1 SKIP_DEPS=1 ./run.sh
  ADMIN_PASSWORD=MyP@ss ./run.sh
EOF
    exit 0
fi

# ---- ١. التحقق من Python ----
step "التحقق من Python"
if ! command -v python3 >/dev/null 2>&1; then
    err "Python 3 غير مثبت. يرجى تثبيت Python 3.10 أو أحدث."
    exit 1
fi
PY_VERSION=$(python3 -c 'import sys; print(f"{sys.version_info.major}.{sys.version_info.minor}")')
PY_MAJOR=$(python3 -c 'import sys; print(sys.version_info.major)')
PY_MINOR=$(python3 -c 'import sys; print(sys.version_info.minor)')
if [ "$PY_MAJOR" -lt 3 ] || { [ "$PY_MAJOR" -eq 3 ] && [ "$PY_MINOR" -lt 10 ]; }; then
    err "Python $PY_VERSION قديم. مطلوب 3.10 أو أحدث."
    exit 1
fi
ok "Python $PY_VERSION"

# ---- ٢. البيئة الافتراضية ----
if [ "${NO_VENV:-0}" != "1" ]; then
    step "البيئة الافتراضية"
    if [ ! -d "$VENV_DIR" ]; then
        info "إنشاء بيئة افتراضية في $VENV_DIR..."
        python3 -m venv "$VENV_DIR" || {
            err "فشل إنشاء البيئة. حاول: NO_VENV=1 ./run.sh"
            exit 1
        }
    fi
    # shellcheck disable=SC1091
    . "$VENV_DIR/bin/activate"
    ok "البيئة الافتراضية مفعّلة"
    PY=python
    PIP="pip"
else
    PY=python3
    PIP="pip3"
fi

# ---- ٣. تثبيت المتطلبات ----
if [ "${SKIP_DEPS:-0}" != "1" ]; then
    step "تثبيت متطلبات Python"
    $PIP install --quiet --upgrade pip 2>&1 | tail -1
    $PIP install --quiet -r requirements.txt
    ok "تم تثبيت المتطلبات"
else
    warn "تم تخطّي تثبيت المتطلبات (SKIP_DEPS=1)"
fi

# ---- ٤. ترحيل قاعدة البيانات ----
step "ترحيل قاعدة البيانات"
$PY manage.py migrate --noinput
ok "تم تطبيق الترحيلات"

# ---- ٤.١ فحص سلامة المخطط ----
# يكتشف الحالة الشائعة: db.sqlite3 من إصدار قديم لكن جدول migrations يدّعي
# أن الترحيلات مطبّقة، فلا يُعيد Django إنشاء الأعمدة الجديدة.
SCHEMA_CHECK_SCRIPT='
import os, django
os.environ.setdefault("DJANGO_SETTINGS_MODULE", "hq_protocol.settings")
django.setup()
from django.db.utils import OperationalError, ProgrammingError
from survivors.models import SurvivorProfile
try:
    SurvivorProfile.objects.filter(birth_governorate="").exists()
except (OperationalError, ProgrammingError):
    raise SystemExit(1)
'
if ! $PY -c "$SCHEMA_CHECK_SCRIPT" 2>/dev/null; then
    warn "اكتُشف مخطط قديم في db.sqlite3 (أعمدة جديدة مفقودة)"
    if [ -f "db.sqlite3" ]; then
        BACKUP="db.sqlite3.old.$(date +%Y%m%d_%H%M%S)"
        cp db.sqlite3 "$BACKUP"
        info "نسخة احتياطية: $BACKUP"
        rm -f db.sqlite3
    fi
    info "إعادة بناء قاعدة البيانات بالمخطط الجديد..."
    $PY manage.py migrate --noinput
    ok "تمت إعادة البناء"
    SCHEMA_REBUILT=1
else
    ok "المخطط سليم"
fi

# ---- ٥. إنشاء/تحديث حساب المسؤول ----
step "حساب المسؤول"
if [ -n "${ADMIN_PASSWORD:-}" ]; then
    $PY manage.py create_admin --password "$ADMIN_PASSWORD"
else
    $PY manage.py create_admin
fi

# ---- ٦. بذر البيانات المرجعية ----
if [ "${SKIP_SEED:-0}" != "1" ]; then
    step "بذر البيانات المرجعية"
    $PY manage.py seed_reference_data
else
    warn "تم تخطّي بذر البيانات (SKIP_SEED=1)"
fi

# ---- ٧. تشغيل السيرفر ----
step "تشغيل السيرفر"
printf "${GREEN}${BOLD}"
cat <<EOF
╔══════════════════════════════════════════════════════════╗
║                                                          ║
║         جمعية حقّنا — HAQQUNA                            ║
║         نظام توثيق ملفات الناجين والمسح الاجتماعي        ║
║                                                          ║
╠══════════════════════════════════════════════════════════╣
EOF
printf "║  ${NC}${BOLD}العنوان:${GREEN}    http://%-44s ║\n" "${HOST}:${PORT}/"
printf "║  ${NC}${BOLD}المستخدم:${GREEN}   %-45s ║\n" "admin"
printf "║  ${NC}${BOLD}كلمة المرور:${GREEN} %-42s ║\n" "${ADMIN_PASSWORD:-haqquna2026}"
printf "║  ${NC}${BOLD}الإدارة:${GREEN}    http://%-44s ║\n" "${HOST}:${PORT}/admin/"
cat <<EOF
║                                                          ║
║  للإيقاف: Ctrl+C                                         ║
╚══════════════════════════════════════════════════════════╝
EOF
printf "${NC}\n"

exec $PY manage.py runserver "$HOST:$PORT"
