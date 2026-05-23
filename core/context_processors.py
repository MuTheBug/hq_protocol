from django.conf import settings


def site_settings(request):
    is_training = getattr(settings, "IS_TRAINING_MODE", False)
    return {
        "ORG_NAME_AR": "جمعية حقّنا",
        "ORG_NAME_EN": "HAQQUNA",
        "ORG_TAGLINE_AR": "الخدمات الاجتماعية · القانون والدفاع والحقوق · التعليم والتمكين",
        "SYSTEM_NAME": "نظام توثيق ملفات الناجين والمسح الاجتماعي",
        "IS_TRAINING_MODE": is_training,
        "ENVIRONMENT_LABEL": "بيئة التدريب" if is_training else "بيئة الإنتاج",
    }
