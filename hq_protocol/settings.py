"""
Django settings for hq_protocol project.

Survivor Documentation System aligned with:
- Istanbul Protocol (Rev. 2, 2022)
- Berkeley Protocol (2022)
- IIIM Methodology for Detention Documentation (Annex A, December 2024)
- Eurojust/ICC Guidelines for Civil Society Organizations (2022)
"""

import os
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parent.parent

# ============================================================
# وضع التشغيل (إنتاج / تدريب) - يفصل قاعدة بيانات التوثيق الفعلي
# عن قاعدة بيانات تدريب المتطوّعين فصلاً تاماً.
# ============================================================
DJANGO_MODE = os.environ.get("DJANGO_MODE", "production").lower()
IS_TRAINING_MODE = DJANGO_MODE == "training"

SECRET_KEY = os.environ.get(
    "DJANGO_SECRET_KEY",
    "django-insecure-training-environment-only-do-not-use-in-production"
    if IS_TRAINING_MODE
    else "django-insecure-^=tqear9g51z^vad2e4lu@79(1rz0%d5l*e!r)y2!akd!s42*_",
)

DEBUG = os.environ.get("DJANGO_DEBUG", "True").lower() == "true"

ALLOWED_HOSTS = ["*"] if DEBUG else os.environ.get("DJANGO_ALLOWED_HOSTS", "").split(",")


INSTALLED_APPS = [
    "django.contrib.admin",
    "django.contrib.auth",
    "django.contrib.contenttypes",
    "django.contrib.sessions",
    "django.contrib.messages",
    "django.contrib.staticfiles",
    "django.contrib.humanize",
    # Third-party
    "django_bootstrap5",
    "crispy_forms",
    "crispy_bootstrap5",
    # Local apps
    "accounts.apps.AccountsConfig",
    "survivors.apps.SurvivorsConfig",
    "social_survey.apps.SocialSurveyConfig",
    "tutorials.apps.TutorialsConfig",
    "mobile_api.apps.MobileApiConfig",
    "core.apps.CoreConfig",
]

MIDDLEWARE = [
    "django.middleware.security.SecurityMiddleware",
    "django.contrib.sessions.middleware.SessionMiddleware",
    "django.middleware.locale.LocaleMiddleware",
    "django.middleware.common.CommonMiddleware",
    "django.middleware.csrf.CsrfViewMiddleware",
    "django.contrib.auth.middleware.AuthenticationMiddleware",
    "django.contrib.messages.middleware.MessageMiddleware",
    "django.middleware.clickjacking.XFrameOptionsMiddleware",
    "accounts.middleware.AuditLogMiddleware",
]

ROOT_URLCONF = "hq_protocol.urls"

TEMPLATES = [
    {
        "BACKEND": "django.template.backends.django.DjangoTemplates",
        "DIRS": [BASE_DIR / "templates"],
        "APP_DIRS": True,
        "OPTIONS": {
            "context_processors": [
                "django.template.context_processors.request",
                "django.contrib.auth.context_processors.auth",
                "django.contrib.messages.context_processors.messages",
                "core.context_processors.site_settings",
            ],
        },
    },
]

WSGI_APPLICATION = "hq_protocol.wsgi.application"

# قاعدة بيانات منفصلة لوضع التدريب
DATABASES = {
    "default": {
        "ENGINE": "django.db.backends.sqlite3",
        "NAME": BASE_DIR / ("db.training.sqlite3" if IS_TRAINING_MODE else "db.sqlite3"),
    }
}

# جلسات مختلفة كي لا تتداخل المصادقة بين البيئتين
SESSION_COOKIE_NAME = "hq_session_training" if IS_TRAINING_MODE else "hq_session"
CSRF_COOKIE_NAME = "hq_csrf_training" if IS_TRAINING_MODE else "hq_csrf"

AUTH_USER_MODEL = "accounts.User"

AUTH_PASSWORD_VALIDATORS = [
    {"NAME": "django.contrib.auth.password_validation.UserAttributeSimilarityValidator"},
    {"NAME": "django.contrib.auth.password_validation.MinimumLengthValidator",
     "OPTIONS": {"min_length": 10}},
    {"NAME": "django.contrib.auth.password_validation.CommonPasswordValidator"},
    {"NAME": "django.contrib.auth.password_validation.NumericPasswordValidator"},
]

LANGUAGE_CODE = "ar"
TIME_ZONE = "Asia/Damascus"
USE_I18N = True
USE_TZ = True

LANGUAGES = [
    ("ar", "العربية"),
    ("en", "English"),
]

LOCALE_PATHS = [BASE_DIR / "locale"]

STATIC_URL = "static/"
STATIC_ROOT = BASE_DIR / "staticfiles"
STATICFILES_DIRS = [BASE_DIR / "static"]

MEDIA_URL = "media/"
MEDIA_ROOT = BASE_DIR / ("media_training" if IS_TRAINING_MODE else "media")

DEFAULT_AUTO_FIELD = "django.db.models.BigAutoField"

LOGIN_URL = "accounts:login"
LOGIN_REDIRECT_URL = "core:dashboard"
LOGOUT_REDIRECT_URL = "accounts:login"

CRISPY_ALLOWED_TEMPLATE_PACKS = "bootstrap5"
CRISPY_TEMPLATE_PACK = "bootstrap5"

SESSION_COOKIE_AGE = 3600 * 4
SESSION_EXPIRE_AT_BROWSER_CLOSE = True
SESSION_COOKIE_HTTPONLY = True
CSRF_COOKIE_HTTPONLY = True

if not DEBUG:
    SECURE_BROWSER_XSS_FILTER = True
    SECURE_CONTENT_TYPE_NOSNIFF = True
    X_FRAME_OPTIONS = "DENY"
    SESSION_COOKIE_SECURE = True
    CSRF_COOKIE_SECURE = True

FILE_UPLOAD_MAX_MEMORY_SIZE = 50 * 1024 * 1024  # 50MB
DATA_UPLOAD_MAX_MEMORY_SIZE = 50 * 1024 * 1024

LOGGING = {
    "version": 1,
    "disable_existing_loggers": False,
    "formatters": {
        "verbose": {
            "format": "{asctime} [{levelname}] {name}: {message}",
            "style": "{",
        },
    },
    "handlers": {
        "audit_file": {
            "level": "INFO",
            "class": "logging.FileHandler",
            "filename": BASE_DIR / ("audit.training.log" if IS_TRAINING_MODE else "audit.log"),
            "formatter": "verbose",
        },
        "console": {
            "level": "INFO",
            "class": "logging.StreamHandler",
            "formatter": "verbose",
        },
    },
    "loggers": {
        "audit": {
            "handlers": ["audit_file", "console"],
            "level": "INFO",
            "propagate": False,
        },
    },
}
