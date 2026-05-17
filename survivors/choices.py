"""قوائم خيارات مرجعية موحّدة للنظام (للسماح بالفلترة والإحصاء الدقيق)."""

from django.utils.translation import gettext_lazy as _


class SyrianGovernorate:
    """المحافظات السورية الـ14 - معايير الأمم المتحدة."""

    DAMASCUS = "damascus"
    RURAL_DAMASCUS = "rural_damascus"
    ALEPPO = "aleppo"
    HOMS = "homs"
    HAMA = "hama"
    LATAKIA = "latakia"
    TARTUS = "tartus"
    IDLIB = "idlib"
    DARAA = "daraa"
    SUWAYDA = "suwayda"
    QUNEITRA = "quneitra"
    RAQQA = "raqqa"
    DEIR_EZ_ZOR = "deir_ez_zor"
    HASAKAH = "hasakah"

    CHOICES = [
        (DAMASCUS, _("دمشق")),
        (RURAL_DAMASCUS, _("ريف دمشق")),
        (ALEPPO, _("حلب")),
        (HOMS, _("حمص")),
        (HAMA, _("حماة")),
        (LATAKIA, _("اللاذقية")),
        (TARTUS, _("طرطوس")),
        (IDLIB, _("إدلب")),
        (DARAA, _("درعا")),
        (SUWAYDA, _("السويداء")),
        (QUNEITRA, _("القنيطرة")),
        (RAQQA, _("الرقة")),
        (DEIR_EZ_ZOR, _("دير الزور")),
        (HASAKAH, _("الحسكة")),
    ]


class Country:
    """البلدان الأكثر استضافة للسوريين."""

    CHOICES = [
        ("SY", _("سوريا")),
        ("TR", _("تركيا")),
        ("LB", _("لبنان")),
        ("JO", _("الأردن")),
        ("IQ", _("العراق")),
        ("EG", _("مصر")),
        ("DE", _("ألمانيا")),
        ("NL", _("هولندا")),
        ("SE", _("السويد")),
        ("FR", _("فرنسا")),
        ("GB", _("بريطانيا")),
        ("AT", _("النمسا")),
        ("BE", _("بلجيكا")),
        ("DK", _("الدنمارك")),
        ("NO", _("النرويج")),
        ("US", _("الولايات المتحدة")),
        ("CA", _("كندا")),
        ("SA", _("السعودية")),
        ("AE", _("الإمارات")),
        ("QA", _("قطر")),
        ("KW", _("الكويت")),
        ("OTHER", _("أخرى")),
    ]


class OccupationCategory:
    """فئات المهنة وقت الاعتقال - للإحصاء."""

    CHOICES = [
        ("student_school", _("طالب مدرسي")),
        ("student_university", _("طالب جامعي")),
        ("teacher", _("معلم/أستاذ")),
        ("doctor", _("طبيب")),
        ("nurse", _("ممرض/ة")),
        ("lawyer", _("محامي")),
        ("engineer", _("مهندس")),
        ("journalist", _("صحفي/إعلامي")),
        ("activist", _("ناشط حقوقي/إنساني")),
        ("civil_servant", _("موظف حكومي")),
        ("military", _("عسكري/أمني")),
        ("merchant", _("تاجر/صاحب عمل")),
        ("worker", _("عامل")),
        ("farmer", _("مزارع")),
        ("driver", _("سائق")),
        ("housewife", _("ربّة منزل")),
        ("religious", _("رجل دين/إمام")),
        ("artist", _("فنان/مبدع")),
        ("unemployed", _("بدون عمل")),
        ("retired", _("متقاعد")),
        ("other", _("أخرى")),
    ]


class PoliticalActivity:
    """فئات النشاط السياسي/الحقوقي وقت الاعتقال."""

    CHOICES = [
        ("peaceful_protest", _("نشاط احتجاجي سلمي")),
        ("media_activism", _("نشاط إعلامي/توثيقي")),
        ("humanitarian", _("عمل إنساني/إغاثي")),
        ("medical_aid", _("إسعاف/علاج للجرحى")),
        ("political_party", _("منتسب لحزب سياسي معارض")),
        ("armed_group_fsa", _("الجيش الحر")),
        ("armed_group_other", _("فصيل مسلح آخر")),
        ("civil_society", _("منظمة مجتمع مدني")),
        ("religious_oppose", _("معارضة على خلفية دينية")),
        ("kurdish_political", _("نشاط سياسي كردي")),
        ("no_activity", _("لا نشاط سياسي - اعتقال عشوائي")),
        ("relative_of", _("بسبب قرابة لشخص آخر")),
        ("unknown_reason", _("السبب غير معلوم")),
        ("other", _("أخرى")),
    ]


class MaritalStatus:
    """الحالة الزوجية."""

    CHOICES = [
        ("single", _("أعزب/عزباء")),
        ("engaged", _("مخطوب/ة")),
        ("married", _("متزوج/ة")),
        ("divorced", _("مطلّق/ة")),
        ("widowed", _("أرمل/أرملة")),
        ("separated", _("منفصل/ة")),
    ]


class InterviewLanguage:
    """لغات المقابلة الشائعة."""

    CHOICES = [
        ("ar", _("العربية - الفصحى")),
        ("ar_levantine", _("العربية - الشامية")),
        ("ku", _("الكردية")),
        ("en", _("الإنجليزية")),
        ("tr", _("التركية")),
        ("de", _("الألمانية")),
        ("fr", _("الفرنسية")),
        ("other", _("أخرى")),
    ]


# قاموس مساعد للترجمة في القوالب
def label_for(choices, value):
    for v, label in choices:
        if v == value:
            return str(label)
    return value
