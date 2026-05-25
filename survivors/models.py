"""
نماذج توثيق الناجين من المعتقلات السورية.

مصممة وفق:
- بروتوكول إسطنبول المحدّث (Istanbul Protocol, Rev. 2, 2022)
- بروتوكول بيركلي (Berkeley Protocol, 2022)
- منهجية الآلية الدولية المحايدة المستقلة لسوريا (IIIM Annex A, 2024)
- دليل Eurojust/ICC للمجتمع المدني (2022)
"""

import hashlib
import uuid

from django.conf import settings
from django.db import models
from django.urls import reverse
from django.utils.translation import gettext_lazy as _

from .choices import (
    Country, InterviewLanguage, MaritalStatus, OccupationCategory,
    PoliticalActivity, SyrianGovernorate,
)


# ============================================================
# ١. القوائم المرجعية (Lookup tables)
# ============================================================

class DetentionFacility(models.Model):
    """فرع/سجن/مكان احتجاز معروف داخل النظام السوري."""

    class Entity(models.TextChoices):
        MILITARY_INTEL = "military_intel", _("المخابرات العسكرية")
        AIR_FORCE_INTEL = "air_force_intel", _("المخابرات الجوية")
        GENERAL_INTEL = "general_intel", _("المخابرات العامة (أمن الدولة)")
        POLITICAL_SEC = "political_sec", _("الأمن السياسي")
        MILITARY_POLICE = "military_police", _("الشرطة العسكرية")
        PRISONS_DEPT = "prisons_dept", _("إدارة السجون")
        OTHER = "other", _("جهة أخرى")

    name_ar = models.CharField(_("اسم الفرع/المركز"), max_length=200)
    name_en = models.CharField(_("الاسم بالإنجليزية"), max_length=200, blank=True)
    branch_number = models.CharField(
        _("رقم الفرع (إن وُجد)"), max_length=20, blank=True,
        help_text=_("مثل: 215، 235، 251 ..."),
    )
    parent_entity = models.CharField(
        _("الجهة الأم"), max_length=30, choices=Entity.choices,
    )
    governorate = models.CharField(
        _("المحافظة"), max_length=30,
        choices=SyrianGovernorate.CHOICES, blank=True, db_index=True,
    )
    address = models.CharField(_("الموقع/العنوان"), max_length=300, blank=True)
    latitude = models.DecimalField(
        _("خط العرض"), max_digits=9, decimal_places=6, null=True, blank=True,
    )
    longitude = models.DecimalField(
        _("خط الطول"), max_digits=9, decimal_places=6, null=True, blank=True,
    )
    notes = models.TextField(_("ملاحظات"), blank=True)

    class Meta:
        verbose_name = _("مركز احتجاز")
        verbose_name_plural = _("مراكز الاحتجاز")
        ordering = ["parent_entity", "name_ar"]

    def __str__(self):
        if self.branch_number:
            return f"{self.name_ar} (فرع {self.branch_number})"
        return self.name_ar


class TortureMethod(models.Model):
    """نمط من أنماط التعذيب أو سوء المعاملة (مصنّف وفق بروتوكول إسطنبول)."""

    class Category(models.TextChoices):
        PHYSICAL = "physical", _("جسدي")
        PSYCHOLOGICAL = "psychological", _("نفسي")
        SEXUAL = "sexual", _("جنسي")
        ENVIRONMENTAL = "environmental", _("ظرفي/بيئي")
        DEPRIVATION = "deprivation", _("حرمان (طعام، نوم، علاج)")

    name_ar = models.CharField(_("الاسم بالعربية"), max_length=200)
    name_en = models.CharField(_("الاسم بالإنجليزية"), max_length=200, blank=True)
    category = models.CharField(_("الفئة"), max_length=20, choices=Category.choices)
    description = models.TextField(_("الوصف"), blank=True)

    class Meta:
        verbose_name = _("نمط تعذيب")
        verbose_name_plural = _("أنماط التعذيب")
        ordering = ["category", "name_ar"]

    def __str__(self):
        return f"[{self.get_category_display()}] {self.name_ar}"


# ============================================================
# ٢. الملف الرئيسي للناجي (Survivor Profile)
# ============================================================

class ActiveSurvivorManager(models.Manager):
    """مدير افتراضي يستبعد الملفات المؤرشفة (لكن يحتفظ بها في DB)."""

    def get_queryset(self):
        return super().get_queryset().filter(is_archived=False)


class SurvivorProfile(models.Model):
    """ملف ناجٍ مُفرج عنه. النظام مخصص للناجين فقط (لا مفقودين ولا متوفين)."""

    # objects = الملفات النشطة فقط · all_objects = شاملاً المؤرشفة (للأدمن)
    objects = ActiveSurvivorManager()
    all_objects = models.Manager()

    class Gender(models.TextChoices):
        MALE = "male", _("ذكر")
        FEMALE = "female", _("أنثى")
        OTHER = "other", _("آخر/لا يصرّح")

    class FileClassification(models.TextChoices):
        A = "A", _("فئة A - جاهز للمحاكم الدولية")
        B = "B", _("فئة B - جاهز للـIIIM ولجنة التحقيق")
        C = "C", _("فئة C - أرشيف/إحصاء فقط")
        DRAFT = "draft", _("مسودة - قيد الجمع")

    # رقم مرجعي فريد (يحلّ محل الاسم في حال طلب إخفاء الهوية)
    case_uid = models.UUIDField(
        _("الرقم المرجعي"), default=uuid.uuid4, editable=False, unique=True,
    )
    case_reference = models.CharField(
        _("رقم القضية الداخلي"), max_length=50, unique=True,
        help_text=_("مثال: HQ-2025-0001"),
    )

    # ---- البيانات البيوغرافية ----
    first_name = models.CharField(_("الاسم"), max_length=100)
    father_name = models.CharField(_("اسم الأب"), max_length=100)
    grandfather_name = models.CharField(_("اسم الجد"), max_length=100, blank=True)
    family_name = models.CharField(_("اسم العائلة"), max_length=100)
    mother_name = models.CharField(_("اسم الأم"), max_length=200, blank=True)
    alias = models.CharField(
        _("الكنية/اللقب"), max_length=100, blank=True,
        help_text=_("أي أسماء مستعارة أو كنى عُرف بها"),
    )

    national_id = models.CharField(
        _("الرقم الوطني السوري"), max_length=20, blank=True, db_index=True,
        help_text=_("11 رقم. يُسمح بالفراغ لكن إذا أُدخل، يجب أن يكون فريداً."),
    )
    birth_date = models.DateField(_("تاريخ الميلاد"), null=True, blank=True)
    birth_date_approximate = models.BooleanField(
        _("تاريخ الميلاد تقريبي"), default=False,
    )
    birth_governorate = models.CharField(
        _("محافظة الولادة"), max_length=30,
        choices=SyrianGovernorate.CHOICES, blank=True, db_index=True,
    )
    birth_place_detail = models.CharField(
        _("مكان الولادة - تفصيلي (مدينة، قرية، حي)"), max_length=200, blank=True,
    )
    gender = models.CharField(
        _("الجنس"), max_length=10, choices=Gender.choices, db_index=True,
    )
    nationality = models.CharField(_("الجنسية"), max_length=100, default="سورية")
    marital_status_at_detention = models.CharField(
        _("الحالة الزوجية وقت الاعتقال"), max_length=20,
        choices=MaritalStatus.CHOICES, blank=True, db_index=True,
    )

    # ---- وقت الاعتقال ----
    address_at_detention = models.TextField(_("عنوان السكن وقت الاعتقال"), blank=True)
    governorate_at_detention = models.CharField(
        _("المحافظة وقت الاعتقال"), max_length=30,
        choices=SyrianGovernorate.CHOICES, blank=True, db_index=True,
    )
    occupation_category = models.CharField(
        _("فئة العمل/الدراسة وقت الاعتقال"), max_length=30,
        choices=OccupationCategory.CHOICES, blank=True, db_index=True,
    )
    occupation_detail = models.CharField(
        _("تفاصيل العمل (اختياري)"), max_length=200, blank=True,
    )
    political_activity_category = models.CharField(
        _("فئة النشاط/الانتماء السياسي"), max_length=30,
        choices=PoliticalActivity.CHOICES, blank=True, db_index=True,
    )
    political_activity_detail = models.TextField(
        _("تفاصيل النشاط السياسي (اختياري)"), blank=True,
    )

    # ---- معلومات اتصال حالية ----
    current_phone = models.CharField(_("رقم الهاتف الحالي"), max_length=30, blank=True)
    current_email = models.EmailField(_("البريد الإلكتروني الحالي"), blank=True)
    current_country = models.CharField(
        _("بلد الإقامة الحالي"), max_length=10,
        choices=Country.CHOICES, blank=True, db_index=True,
    )
    current_governorate = models.CharField(
        _("المحافظة الحالية (داخل سوريا)"), max_length=30,
        choices=SyrianGovernorate.CHOICES, blank=True, db_index=True,
    )
    current_city = models.CharField(
        _("المدينة/البلدة الحالية"), max_length=100, blank=True,
    )
    next_of_kin_name = models.CharField(_("اسم قريب للتواصل"), max_length=200, blank=True)
    next_of_kin_relation = models.CharField(_("صلة القرابة"), max_length=80, blank=True)
    next_of_kin_phone = models.CharField(_("رقم القريب"), max_length=30, blank=True)

    # ---- الصور ----
    photo_recent = models.ImageField(
        _("صورة حديثة"), upload_to="survivors/photos/recent/", blank=True, null=True,
    )
    photo_before_detention = models.ImageField(
        _("صورة قبل الاعتقال"),
        upload_to="survivors/photos/before/", blank=True, null=True,
    )

    # ---- التصنيف الداخلي ----
    file_classification = models.CharField(
        _("تصنيف الملف"), max_length=10, choices=FileClassification.choices,
        default=FileClassification.DRAFT, db_index=True,
    )
    # النقاط تُحسَب تلقائياً من البيانات والأدلة (signals)
    reliability_score = models.PositiveSmallIntegerField(
        _("درجة الموثوقية (0-5) - محسوبة آلياً"), default=0, editable=False,
    )
    corroboration_score = models.PositiveSmallIntegerField(
        _("درجة التحقق المتقاطع (0-5) - محسوبة آلياً"), default=0, editable=False,
    )
    completeness_score = models.PositiveSmallIntegerField(
        _("درجة الاكتمال (0-5) - محسوبة آلياً"), default=0, editable=False,
    )

    # ---- بيانات وصفية ----
    documenter = models.ForeignKey(
        settings.AUTH_USER_MODEL, on_delete=models.SET_NULL, null=True,
        related_name="documented_survivors", verbose_name=_("الموثّق المسؤول"),
        db_index=True,
    )

    # ---- الأرشفة (Soft-delete) - مطلب IIIM/ICC لحفظ الأدلة ----
    is_archived = models.BooleanField(
        _("مؤرشف"), default=False, db_index=True,
        help_text=_("بدلاً من الحذف النهائي، نُؤرشف الملفات لحفظ الأدلة"),
    )
    archived_at = models.DateTimeField(_("تاريخ الأرشفة"), null=True, blank=True)
    archived_by = models.ForeignKey(
        settings.AUTH_USER_MODEL, on_delete=models.SET_NULL, null=True, blank=True,
        related_name="archived_survivors", verbose_name=_("أرشفه"),
    )
    archive_reason = models.TextField(_("سبب الأرشفة"), blank=True)

    # ---- الإحالة الطبية والنفسية ----
    medical_referral_offered = models.BooleanField(
        _("هل عُرضت إحالة طبية؟"), default=False,
    )
    psychological_referral_offered = models.BooleanField(
        _("هل عُرضت إحالة نفسية؟"), default=False,
    )
    legal_aid_offered = models.BooleanField(
        _("هل عُرضت مساعدة قانونية؟"), default=False,
    )
    referral_notes = models.TextField(_("تفاصيل الإحالات"), blank=True)

    created_at = models.DateTimeField(auto_now_add=True, db_index=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        verbose_name = _("ملف ناجٍ")
        verbose_name_plural = _("ملفات الناجين")
        ordering = ["-created_at"]
        permissions = [
            ("view_sensitive_data", "Can view sensitive identifying data"),
            ("export_files", "Can export survivor files to external bodies"),
        ]

    def __str__(self):
        return f"{self.case_reference} - {self.full_name}"

    def get_absolute_url(self):
        return reverse("survivors:detail", kwargs={"pk": self.pk})

    @property
    def full_name(self):
        parts = [
            self.first_name, self.father_name,
            self.grandfather_name, self.family_name,
        ]
        return " ".join(p for p in parts if p)

    @property
    def age_at_detention(self):
        first_detention = self.detention_events.order_by("detention_date").first()
        if not first_detention or not self.birth_date:
            return None
        delta = first_detention.detention_date - self.birth_date
        return delta.days // 365

    @property
    def total_witnesses(self):
        return self.witnesses.count()

    @property
    def independent_witnesses_count(self):
        return self.witnesses.filter(
            is_independent=True, consent_to_use_testimony=True,
        ).count()

    @property
    def total_documents(self):
        return self.documents.count()

    @property
    def total_interviews(self):
        return self.interviews.count()

    @property
    def total_videos(self):
        from django.db.models import Q
        return (
            self.documents.filter(document_type__in=["video", "audio"]).count()
            + InterviewMedia.objects.filter(
                interview__survivor=self,
                media_type__in=["video", "audio"],
            ).count()
        )

    @property
    def overall_score(self):
        scores = [self.reliability_score, self.corroboration_score, self.completeness_score]
        if not any(scores):
            return 0
        return round(sum(scores) / 3, 1)

    # ---- منهج النقاط التلقائية ----
    def compute_reliability(self):
        """الموثوقية (0-5): اتساق وتفصيل وتوثيق المقابلة."""
        score = 0
        periods = self.detention_periods.all()
        if periods.exists():
            score += 1
            if any(len(p.torture_description or "") > 200 for p in periods):
                score += 1
        events = self.detention_events.all()
        if events.exists() and any(len(e.circumstances or "") > 150 for e in events):
            score += 1
        # إجراء أول مقابلة (تجنّب إعادة الصدمة) أو مقابلة مسجَّلة
        interviews = self.interviews.all()
        if interviews.filter(is_first=True).exists():
            score += 1
        if interviews.filter(recorded=True).exists():
            score += 1
        return min(score, 5)

    def compute_corroboration(self):
        """التحقق المتقاطع (0-5): شهود مستقلون + وثائق + أدلة طبية."""
        score = 0
        independent = self.witnesses.filter(
            is_independent=True, consent_to_use_testimony=True,
        ).count()
        score += min(independent, 2)
        if self.documents.filter(
            document_type__in=[
                "official_regime", "court_document", "arrest_warrant",
                "release_order", "transfer_order", "international_court",
            ]
        ).exists():
            score += 1
        if self.medical_assessments.filter(istanbul_protocol_compliant=True).exists():
            score += 1
        if self.documents.exclude(file_hash_sha256="").exists():
            score += 1
        return min(score, 5)

    def compute_completeness(self):
        """الاكتمال (0-5): أقسام الملف الأساسية مغطّاة."""
        score = 0
        if self.first_name and self.father_name and self.family_name and self.gender:
            score += 1
        try:
            if self.consent.is_fully_compliant:
                score += 1
        except Exception:
            pass
        if self.detention_events.exists():
            score += 1
        if self.detention_periods.exists():
            score += 1
        if hasattr(self, "release_event"):
            score += 1
        return min(score, 5)

    def clean(self):
        """التحقق من فرادة الرقم الوطني (مع السماح بالفراغ)."""
        from django.core.exceptions import ValidationError
        super().clean()
        if self.national_id:
            duplicate = type(self).all_objects.filter(
                national_id=self.national_id,
            ).exclude(pk=self.pk).first()
            if duplicate:
                raise ValidationError({
                    "national_id": _(
                        "هذا الرقم الوطني مُستخدَم في الملف %(ref)s. "
                        "إذا كان نفس الشخص، عدّل الملف القائم بدل إنشاء جديد."
                    ) % {"ref": duplicate.case_reference},
                })

    def recompute_scores(self, save=True):
        """يحدّث الدرجات الثلاث (يُستدعى من signals تلقائياً)."""
        rel = self.compute_reliability()
        cor = self.compute_corroboration()
        com = self.compute_completeness()
        if save:
            type(self).objects.filter(pk=self.pk).update(
                reliability_score=rel,
                corroboration_score=cor,
                completeness_score=com,
            )
        self.reliability_score = rel
        self.corroboration_score = cor
        self.completeness_score = com

    # ---- شرح تفصيلي لكل درجة (لعرضه للمستخدم) ----
    def reliability_breakdown(self):
        """يُرجع قائمة (المعيار, مُكتسب؟, التلميح لتحسينه) - 5 معايير."""
        periods = self.detention_periods.all()
        has_periods = periods.exists()
        has_long_torture = any(len(p.torture_description or "") > 200 for p in periods)
        events = self.detention_events.all()
        has_long_circ = events.exists() and any(
            len(e.circumstances or "") > 150 for e in events
        )
        interviews = self.interviews.all()
        has_first = interviews.filter(is_first=True).exists()
        has_recorded = interviews.filter(recorded=True).exists()
        return [
            ("فترة احتجاز موثّقة", has_periods,
             "أضف فترة احتجاز في تبويب «الاحتجاز» مع تحديد الفرع والفترة"),
            ("وصف تعذيب مفصّل (>200 حرف)", has_long_torture,
             "في فترة الاحتجاز، اكتب «وصف تفصيلي للتعذيب» بنص طويل (بأقوال الناجي)"),
            ("ظروف اعتقال مفصّلة (>150 حرف)", has_long_circ,
             "في «واقعة الاعتقال»، املأ حقل «ظروف الاعتقال بالتفصيل» (>150 حرف)"),
            ("مقابلة أولى مسجَّلة كـ Interview", has_first,
             "أضف مقابلة من تبويب «المقابلات» وعلّم خانة «المقابلة الأولى»"),
            ("مقابلة بتسجيل صوت/فيديو", has_recorded,
             "في المقابلة، فعّل «مسجَّلة» وارفع فيديو/صوت من زر «رفع ملف»"),
        ]

    def corroboration_breakdown(self):
        independent = self.witnesses.filter(
            is_independent=True, consent_to_use_testimony=True,
        ).count()
        return [
            ("شاهد مستقل أول (موافقة موقّعة)", independent >= 1,
             "أضف شاهداً من تبويب «الشهود»، علّم «مستقل» و«موافقة على استخدام شهادته»"),
            ("شاهد مستقل ثانٍ", independent >= 2,
             "أضف شاهداً ثانياً مستقلاً (شاهدان أفضل من واحد)"),
            ("وثيقة رسمية (نظام/قضائية/دولية)", self.documents.filter(
                document_type__in=[
                    "official_regime", "court_document", "arrest_warrant",
                    "release_order", "transfer_order", "international_court",
                ]
            ).exists(),
             "ارفع وثيقة من «الوثائق»: نوعها رسمي (أمر اعتقال، أمر إفراج، إلخ)"),
            ("تقييم طبي متوافق إسطنبول",
             self.medical_assessments.filter(istanbul_protocol_compliant=True).exists(),
             "أضف تقييماً طبياً من «الطبي/النفسي» وعلّم «متوافق مع بروتوكول إسطنبول»"),
            ("وثيقة ببصمة SHA-256",
             self.documents.exclude(file_hash_sha256="").exists(),
             "ارفع أي وثيقة - البصمة تُحسب آلياً للسلامة"),
        ]

    def completeness_breakdown(self):
        has_consent = False
        try:
            has_consent = self.consent.is_fully_compliant
        except Exception:
            pass
        return [
            ("بيانات هوية أساسية", bool(
                self.first_name and self.father_name
                and self.family_name and self.gender
            ), "أكمل الاسم الرباعي والجنس في الملف الأساسي"),
            ("موافقة مستنيرة مكتملة", has_consent,
             "املأ «الموافقة المستنيرة» وعلّم: شُرح حق الانسحاب، شُرحت السرّية، شُرحت الاستخدامات"),
            ("واقعة اعتقال", self.detention_events.exists(),
             "أضف «واقعة اعتقال» (التاريخ، المكان، الجهة المعتقِلة)"),
            ("فترة احتجاز", self.detention_periods.exists(),
             "أضف فترة احتجاز واحدة على الأقل (في أي فرع)"),
            ("بيانات الإفراج", hasattr(self, "release_event"),
             "املأ «بيانات الإفراج» من تبويب الاحتجاز"),
        ]

    def all_breakdowns(self):
        return {
            "reliability": self.reliability_breakdown(),
            "corroboration": self.corroboration_breakdown(),
            "completeness": self.completeness_breakdown(),
        }


# ============================================================
# ٣. الموافقة المستنيرة (Informed Consent) — طبقية
# ============================================================

class InformedConsent(models.Model):
    """الموافقة المستنيرة الطبقية - الناجي يحدد بالضبط مع مَن تُشارَك معلوماته."""

    survivor = models.OneToOneField(
        SurvivorProfile, on_delete=models.CASCADE, related_name="consent",
    )

    consent_documented = models.BooleanField(
        _("هل تم أخذ الموافقة المستنيرة؟"), default=False,
    )
    consent_date = models.DateField(_("تاريخ الموافقة"), null=True, blank=True)
    consent_witness = models.CharField(
        _("شاهد على الموافقة"), max_length=200, blank=True,
    )
    consent_form_file = models.FileField(
        _("نموذج الموافقة الموقّع (PDF/صورة)"),
        upload_to="survivors/consent/", blank=True, null=True,
    )

    # الموافقة الطبقية - يحدد الناجي مع أي جهة يُسمح بمشاركة ملفه
    share_with_iiim = models.BooleanField(_("مشاركة مع الـIIIM"), default=False)
    share_with_coi = models.BooleanField(_("مشاركة مع لجنة التحقيق الأممية"), default=False)
    share_with_icc = models.BooleanField(_("مشاركة مع المحكمة الجنائية الدولية"), default=False)
    share_with_universal_jurisdiction = models.BooleanField(
        _("مشاركة مع محاكم الولاية القضائية العالمية"), default=False,
    )
    share_with_partner_orgs = models.BooleanField(
        _("مشاركة مع منظمات شريكة"), default=False,
    )
    share_with_media = models.BooleanField(_("مشاركة مع الإعلام"), default=False)
    share_publicly = models.BooleanField(
        _("نشر علني (تقارير، مواقع، إلخ)"), default=False,
    )

    # خيارات الهوية
    anonymize_name = models.BooleanField(_("إخفاء الاسم"), default=False)
    anonymize_photo = models.BooleanField(_("إخفاء الصورة"), default=False)
    anonymize_location = models.BooleanField(_("إخفاء الموقع"), default=False)
    anonymize_family_details = models.BooleanField(
        _("إخفاء تفاصيل العائلة"), default=False,
    )

    # حق الانسحاب
    withdrawal_right_explained = models.BooleanField(
        _("شُرح حق الانسحاب"), default=False,
    )
    confidentiality_limits_explained = models.BooleanField(
        _("شُرحت حدود السرّية"), default=False,
    )
    intended_uses_explained = models.BooleanField(
        _("شُرحت الاستخدامات المحتملة"), default=False,
    )

    # سحب الموافقة لاحقاً
    consent_withdrawn = models.BooleanField(_("سُحبت الموافقة"), default=False)
    withdrawal_date = models.DateField(_("تاريخ سحب الموافقة"), null=True, blank=True)
    withdrawal_reason = models.TextField(_("سبب السحب"), blank=True)

    notes = models.TextField(_("ملاحظات إضافية"), blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        verbose_name = _("موافقة مستنيرة")
        verbose_name_plural = _("نماذج الموافقات المستنيرة")

    def __str__(self):
        return f"موافقة {self.survivor.case_reference}"

    # شرط Q موحّد - يُستخدم في الـviews لفلترة Survivors بموافقات مكتملة
    @staticmethod
    def fully_compliant_q():
        from django.db.models import Q
        return Q(
            consent__consent_documented=True,
            consent__withdrawal_right_explained=True,
            consent__confidentiality_limits_explained=True,
            consent__intended_uses_explained=True,
            consent__consent_withdrawn=False,
        )

    @property
    def is_fully_compliant(self):
        return all([
            self.consent_documented,
            self.withdrawal_right_explained,
            self.confidentiality_limits_explained,
            self.intended_uses_explained,
            not self.consent_withdrawn,
        ])


# ============================================================
# ٤. واقعة الاعتقال والاحتجاز
# ============================================================

class DetentionEvent(models.Model):
    """واقعة اعتقال محددة (قد يكون للناجي أكثر من واقعة)."""

    survivor = models.ForeignKey(
        SurvivorProfile, on_delete=models.CASCADE, related_name="detention_events",
    )
    detention_date = models.DateField(_("تاريخ الاعتقال"))
    date_approximate = models.BooleanField(_("التاريخ تقريبي"), default=False)
    detention_location = models.CharField(
        _("مكان الاعتقال (شارع، نقطة تفتيش، البيت...)"), max_length=300,
    )
    governorate = models.CharField(
        _("المحافظة"), max_length=30,
        choices=SyrianGovernorate.CHOICES, blank=True, db_index=True,
    )
    arresting_entity = models.CharField(
        _("الجهة المعتقِلة (الاسم الكامل)"), max_length=300,
        help_text=_("مثال: المخابرات الجوية - فرع التحقيق - المطار"),
    )
    arresting_personnel_details = models.TextField(
        _("أسماء/رتب/علامات مميزة لعناصر الاعتقال"), blank=True,
    )
    reason_stated = models.TextField(_("السبب المُعلَن (إن وُجد)"), blank=True)
    circumstances = models.TextField(_("ظروف الاعتقال بالتفصيل"))
    witnesses_to_arrest = models.TextField(
        _("شهود على الاعتقال (جيران، عابرو سبيل...)"), blank=True,
    )
    family_notified = models.BooleanField(_("هل أُبلغت العائلة؟"), default=False)
    notes = models.TextField(_("ملاحظات"), blank=True)

    class Meta:
        verbose_name = _("واقعة اعتقال")
        verbose_name_plural = _("وقائع الاعتقال")
        ordering = ["detention_date"]

    def __str__(self):
        return f"اعتقال {self.survivor.case_reference} - {self.detention_date}"


class DetentionPeriod(models.Model):
    """فترة احتجاز في مركز معين - تُشكّل الخط الزمني (Timeline)."""

    survivor = models.ForeignKey(
        SurvivorProfile, on_delete=models.CASCADE, related_name="detention_periods",
    )
    detention_event = models.ForeignKey(
        DetentionEvent, on_delete=models.SET_NULL, null=True, blank=True,
        related_name="periods", verbose_name=_("واقعة الاعتقال المرتبطة"),
    )
    facility = models.ForeignKey(
        DetentionFacility, on_delete=models.PROTECT,
        related_name="detention_periods", verbose_name=_("مركز الاحتجاز"),
        db_index=True,
    )
    from_date = models.DateField(_("من تاريخ"))
    from_date_approximate = models.BooleanField(_("التاريخ تقريبي"), default=False)
    to_date = models.DateField(_("إلى تاريخ"), null=True, blank=True)
    to_date_approximate = models.BooleanField(_("التاريخ تقريبي"), default=False)
    order_index = models.PositiveIntegerField(
        _("ترتيب الفترة"), default=0,
        help_text=_("لترتيب الفترات تصاعدياً"),
    )

    # ظروف الاحتجاز
    cell_description = models.TextField(_("وصف الزنزانة (حجمها، تهويتها...)"), blank=True)
    cellmates_count = models.PositiveIntegerField(
        _("عدد المحتجزين معه"), null=True, blank=True,
    )
    food_water = models.TextField(_("الطعام والماء"), blank=True)
    sleep_conditions = models.TextField(_("ظروف النوم"), blank=True)
    hygiene_conditions = models.TextField(_("النظافة والحمّام"), blank=True)
    medical_care = models.TextField(_("الرعاية الطبية"), blank=True)
    contact_with_outside = models.TextField(_("التواصل مع الخارج"), blank=True)

    # الانتهاكات
    torture_methods = models.ManyToManyField(
        TortureMethod, blank=True, related_name="periods",
        verbose_name=_("أنماط التعذيب الموثَّقة"),
    )
    torture_description = models.TextField(
        _("وصف تفصيلي للتعذيب"), blank=True,
        help_text=_("بأقوال الناجي مباشرة قدر الإمكان"),
    )
    sexual_violence_reported = models.BooleanField(
        _("بلاغ عن عنف جنسي"), default=False,
    )
    sexual_violence_details = models.TextField(
        _("تفاصيل العنف الجنسي (بحساسية)"), blank=True,
    )
    witnessed_deaths = models.TextField(
        _("شهد على وفيات داخل المعتقل (أسماء، تواريخ، أوصاف)"), blank=True,
    )
    witnessed_others = models.TextField(
        _("معتقلون آخرون شاهدهم وقد يكونون مصدر تأكيد"), blank=True,
    )

    notes = models.TextField(_("ملاحظات إضافية"), blank=True)

    class Meta:
        verbose_name = _("فترة احتجاز")
        verbose_name_plural = _("فترات الاحتجاز")
        ordering = ["survivor", "order_index", "from_date"]

    def __str__(self):
        return f"{self.survivor.case_reference} - {self.facility} ({self.from_date})"

    @property
    def duration_days(self):
        if not self.to_date:
            return None
        return (self.to_date - self.from_date).days


class ReleaseEvent(models.Model):
    """واقعة الإفراج عن الناجي."""

    class ReleaseType(models.TextChoices):
        UNCONDITIONAL = "unconditional", _("إفراج غير مشروط")
        CONDITIONAL = "conditional", _("إفراج مشروط")
        AMNESTY = "amnesty", _("عفو عام")
        SETTLEMENT = "settlement", _("تسوية وضع")
        BRIBE = "bribe", _("بدفع رشوة")
        EXCHANGE = "exchange", _("تبادل/صفقة")
        ESCAPE = "escape", _("فرار")
        TRANSFER_OUT = "transfer_out", _("نقل لجهة أخرى")
        UNKNOWN = "unknown", _("غير معلوم")

    survivor = models.OneToOneField(
        SurvivorProfile, on_delete=models.CASCADE, related_name="release_event",
    )
    release_date = models.DateField(_("تاريخ الإفراج"))
    release_type = models.CharField(
        _("نوع الإفراج"), max_length=20, choices=ReleaseType.choices,
    )
    release_location = models.CharField(_("مكان الإفراج"), max_length=200, blank=True)
    bribe_amount = models.CharField(
        _("قيمة الرشوة (إن وُجدت)"), max_length=100, blank=True,
    )
    conditions = models.TextField(_("شروط الإفراج"), blank=True)
    circumstances = models.TextField(_("ظروف الإفراج"))

    class Meta:
        verbose_name = _("واقعة إفراج")
        verbose_name_plural = _("وقائع الإفراج")

    def __str__(self):
        return f"إفراج {self.survivor.case_reference} - {self.release_date}"


# ============================================================
# ٥. الشهود (Cross-corroboration)
# ============================================================

class Witness(models.Model):
    """شاهد متقاطع - معتقل آخر شاهد الناجي في الاحتجاز."""

    class RelationshipBefore(models.TextChoices):
        STRANGER = "stranger", _("لم يكن يعرفه")
        ACQUAINTANCE = "acquaintance", _("معرفة")
        FRIEND = "friend", _("صديق")
        RELATIVE = "relative", _("قريب")
        COLLEAGUE = "colleague", _("زميل عمل/دراسة")

    survivor = models.ForeignKey(
        SurvivorProfile, on_delete=models.CASCADE, related_name="witnesses",
        verbose_name=_("الناجي المُشهَد عليه"),
    )
    witness_name = models.CharField(_("اسم الشاهد"), max_length=200)
    witness_case_reference = models.CharField(
        _("رقم ملف الشاهد (إن كان موثقاً)"), max_length=50, blank=True,
    )
    witness_phone = models.CharField(_("هاتف الشاهد"), max_length=30, blank=True)
    witness_current_location = models.CharField(
        _("الموقع الحالي للشاهد"), max_length=200, blank=True,
    )

    facility_witnessed_at = models.ForeignKey(
        DetentionFacility, on_delete=models.PROTECT,
        verbose_name=_("الفرع/المكان الذي رآه فيه"),
    )
    period_from = models.DateField(_("من تاريخ"))
    period_to = models.DateField(_("إلى تاريخ"), null=True, blank=True)
    cell_number = models.CharField(_("رقم الزنزانة (إن وُجد)"), max_length=50, blank=True)

    how_recognized = models.TextField(
        _("كيف تعرّف عليه؟ (الاسم، الوجه، حادثة...)"),
    )
    distinguishing_details = models.TextField(
        _("تفاصيل مميزة لاحظها"), blank=True,
    )
    specific_incidents = models.TextField(
        _("حوادث محددة شهدها"), blank=True,
    )
    relationship_before = models.CharField(
        _("علاقة الشاهد بالناجي قبل الاعتقال"),
        max_length=20, choices=RelationshipBefore.choices,
        default=RelationshipBefore.STRANGER,
    )

    # الاستقلالية
    is_independent = models.BooleanField(
        _("شاهد مستقل (لم يلتقِ بالناجي بعد الإفراج قبل الإدلاء بشهادته)"),
        default=False,
    )
    met_after_release = models.BooleanField(_("التقيا بعد الإفراج"), default=False)

    # الموافقة الموقّعة من الشاهد
    consent_to_use_testimony = models.BooleanField(
        _("موافقة الشاهد على استخدام شهادته"), default=False,
    )
    declaration_signed = models.BooleanField(_("بيان موقّع"), default=False)
    declaration_date = models.DateField(_("تاريخ البيان"), null=True, blank=True)
    declaration_file = models.FileField(
        _("ملف البيان الموقّع"), upload_to="survivors/declarations/",
        blank=True, null=True,
    )

    full_testimony = models.TextField(_("نص الشهادة الكامل"))
    documenter = models.ForeignKey(
        settings.AUTH_USER_MODEL, on_delete=models.SET_NULL, null=True,
        verbose_name=_("الموثّق الذي أخذ الشهادة"),
    )
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        verbose_name = _("شاهد")
        verbose_name_plural = _("الشهود")
        ordering = ["-created_at"]

    def __str__(self):
        return f"{self.witness_name} → {self.survivor.case_reference}"


# ============================================================
# ٦. الوثائق الداعمة
# ============================================================

def document_upload_path(instance, filename):
    # UUID prefix لمنع التصادمات + الحفاظ على اسم الملف الأصلي للتعرّف
    prefix = uuid.uuid4().hex[:8]
    return f"survivors/documents/{instance.survivor.case_reference}/{prefix}_{filename}"


class SupportingDocument(models.Model):
    """وثيقة داعمة لملف الناجي."""

    class DocumentType(models.TextChoices):
        OFFICIAL_REGIME = "official_regime", _("وثيقة رسمية من جهة سورية")
        COURT_DOCUMENT = "court_document", _("وثيقة قضائية (محكمة عسكرية/ميدانية)")
        ARREST_WARRANT = "arrest_warrant", _("أمر اعتقال")
        RELEASE_ORDER = "release_order", _("أمر إفراج")
        TRANSFER_ORDER = "transfer_order", _("أمر إحالة/نقل")
        INTERNATIONAL_COURT = "international_court", _("وثيقة من محكمة دولية/IIIM")
        LEAKED = "leaked", _("وثيقة مسرّبة (قيصر، تسريبات الفروع...)")
        FAMILY_VISIT = "family_visit", _("كرت زيارة/إيصال زيارة")
        FAMILY_REMITTANCE = "family_remittance", _("حوالة مالية للسجن")
        LAWYER = "lawyer", _("وثيقة من محامٍ")
        MEDIA = "media", _("مادة إعلامية")
        SOCIAL_MEDIA = "social_media", _("منشور وسائل تواصل")
        PHOTO = "photo", _("صورة فوتوغرافية")
        VIDEO = "video", _("فيديو")
        AUDIO = "audio", _("تسجيل صوتي")
        OTHER = "other", _("أخرى")

    survivor = models.ForeignKey(
        SurvivorProfile, on_delete=models.CASCADE, related_name="documents",
    )
    document_type = models.CharField(
        _("نوع الوثيقة"), max_length=30, choices=DocumentType.choices,
        db_index=True,
    )
    title = models.CharField(_("عنوان الوثيقة"), max_length=300)
    description = models.TextField(_("الوصف والمحتوى"))
    file = models.FileField(_("الملف"), upload_to=document_upload_path)
    file_hash_sha256 = models.CharField(
        _("بصمة SHA-256 (Chain of Custody)"), max_length=64, blank=True,
    )
    file_size_bytes = models.BigIntegerField(_("حجم الملف"), null=True, blank=True)

    # سلسلة الحيازة (Chain of Custody)
    source_description = models.TextField(
        _("مصدر الوثيقة وكيفية الحصول عليها"),
        help_text=_("سلسلة الحيازة الكاملة - مَن، متى، أين، كيف"),
    )
    date_obtained = models.DateField(_("تاريخ الاستلام"))
    obtained_by = models.ForeignKey(
        settings.AUTH_USER_MODEL, on_delete=models.SET_NULL, null=True,
        related_name="obtained_documents", verbose_name=_("استلمها"),
    )

    # للوثائق المسرّبة على الإنترنت (Berkeley Protocol)
    original_url = models.URLField(_("الرابط الأصلي"), blank=True)
    url_archived_at = models.URLField(
        _("نسخة مؤرشفة (Archive.org)"), blank=True,
    )
    access_date = models.DateTimeField(
        _("تاريخ ووقت الوصول"), null=True, blank=True,
    )
    metadata_verified = models.BooleanField(
        _("تم التحقق من الميتاداتا"), default=False,
    )
    forensic_analysis = models.TextField(
        _("التحليل الجنائي/التقني (إن وُجد)"), blank=True,
    )

    # للوثائق الرسمية
    document_date = models.DateField(_("تاريخ الوثيقة نفسها"), null=True, blank=True)
    document_reference_number = models.CharField(
        _("الرقم المرجعي للوثيقة"), max_length=100, blank=True,
    )
    issuing_authority = models.CharField(
        _("الجهة المُصدرة"), max_length=200, blank=True,
    )

    notes = models.TextField(_("ملاحظات"), blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        verbose_name = _("وثيقة داعمة")
        verbose_name_plural = _("الوثائق الداعمة")
        ordering = ["-date_obtained"]

    def __str__(self):
        return f"{self.title} ({self.get_document_type_display()})"

    def save(self, *args, **kwargs):
        if self.file and not self.file_hash_sha256:
            try:
                self.file.seek(0)
                hasher = hashlib.sha256()
                for chunk in iter(lambda: self.file.read(4096), b""):
                    hasher.update(chunk)
                self.file_hash_sha256 = hasher.hexdigest()
                self.file.seek(0)
                self.file_size_bytes = self.file.size
            except Exception:
                pass
        super().save(*args, **kwargs)


class ChainOfCustodyLog(models.Model):
    """سجل تتبع لكل عملية على الوثيقة (Chain of Custody)."""

    class Action(models.TextChoices):
        COLLECTED = "collected", _("استلام")
        TRANSFERRED = "transferred", _("نقل ليد أخرى")
        ACCESSED = "accessed", _("اطلاع")
        COPIED = "copied", _("نسخ")
        SHARED_EXTERNAL = "shared_external", _("مشاركة مع جهة خارجية")
        ARCHIVED = "archived", _("أرشفة")
        VERIFIED = "verified", _("تحقق")

    document = models.ForeignKey(
        SupportingDocument, on_delete=models.CASCADE, related_name="custody_log",
    )
    action = models.CharField(_("الإجراء"), max_length=30, choices=Action.choices)
    by_user = models.ForeignKey(
        settings.AUTH_USER_MODEL, on_delete=models.SET_NULL, null=True,
        verbose_name=_("نفّذه"),
    )
    recipient = models.CharField(
        _("المُستلِم (الشخص/الجهة)"), max_length=200, blank=True,
    )
    timestamp = models.DateTimeField(_("الوقت"), auto_now_add=True)
    location = models.CharField(_("المكان"), max_length=200, blank=True)
    notes = models.TextField(_("ملاحظات"), blank=True)
    signature_file = models.FileField(
        _("توقيع (إن وُجد)"), upload_to="custody/signatures/", blank=True, null=True,
    )

    class Meta:
        verbose_name = _("سجل سلسلة حيازة")
        verbose_name_plural = _("سجلات سلسلة الحيازة")
        ordering = ["-timestamp"]

    def __str__(self):
        return f"{self.document} - {self.get_action_display()} - {self.timestamp}"


# ============================================================
# ٧. التقييم الطبي والنفسي
# ============================================================

class MedicalAssessment(models.Model):
    """تقييم طبي/نفسي وفق بروتوكول إسطنبول."""

    class AssessmentType(models.TextChoices):
        PHYSICAL = "physical", _("جسدي")
        PSYCHOLOGICAL = "psychological", _("نفسي")
        COMPREHENSIVE = "comprehensive", _("شامل")

    survivor = models.ForeignKey(
        SurvivorProfile, on_delete=models.CASCADE, related_name="medical_assessments",
    )
    assessment_type = models.CharField(
        _("نوع التقييم"), max_length=20, choices=AssessmentType.choices,
    )
    assessment_date = models.DateField(_("تاريخ التقييم"))
    assessor_name = models.CharField(_("اسم الفاحص"), max_length=200)
    assessor_credentials = models.CharField(
        _("المؤهلات والاختصاص"), max_length=300,
    )
    assessor_organization = models.CharField(
        _("المنظمة (مثل LDHR)"), max_length=200, blank=True,
    )
    istanbul_protocol_compliant = models.BooleanField(
        _("متوافق مع بروتوكول إسطنبول"), default=False,
    )

    physical_findings = models.TextField(_("النتائج الجسدية"), blank=True)
    scars_description = models.TextField(_("وصف الندوب والإصابات"), blank=True)
    disabilities = models.TextField(_("الإعاقات المكتسبة"), blank=True)

    psychological_findings = models.TextField(_("النتائج النفسية"), blank=True)
    ptsd_indicators = models.BooleanField(_("علامات اضطراب ما بعد الصدمة"), default=False)
    depression_indicators = models.BooleanField(_("علامات اكتئاب"), default=False)
    anxiety_indicators = models.BooleanField(_("علامات قلق"), default=False)

    class Consistency(models.TextChoices):
        NOT_ASSESSED = "not_assessed", _("لم يُقَيَّم")
        NOT_CONSISTENT = "not_consistent", _("غير متوافق")
        CONSISTENT = "consistent", _("متوافق")
        HIGHLY_CONSISTENT = "highly_consistent", _("متوافق بدرجة عالية")
        TYPICAL = "typical", _("نمطي/مطابق تماماً")
        DIAGNOSTIC = "diagnostic", _("تشخيصي - دليل قاطع")

    consistency_with_account = models.CharField(
        _("مدى توافق النتائج مع رواية الناجي"), max_length=30,
        choices=Consistency.choices, default=Consistency.NOT_ASSESSED,
        help_text=_("التصنيف الإسطنبولي القياسي لمصداقية الإصابات"),
    )
    consistency_notes = models.TextField(
        _("ملاحظات على التوافق"), blank=True,
    )

    report_file = models.FileField(
        _("ملف التقرير"), upload_to="survivors/medical/", blank=True, null=True,
    )
    consent_to_share = models.BooleanField(
        _("موافقة على مشاركة التقرير"), default=False,
    )

    notes = models.TextField(_("ملاحظات"), blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        verbose_name = _("تقييم طبي")
        verbose_name_plural = _("التقييمات الطبية")
        ordering = ["-assessment_date"]

    def __str__(self):
        return f"{self.get_assessment_type_display()} - {self.survivor.case_reference} - {self.assessment_date}"


class LongTermImpact(models.Model):
    """الأثر طويل الأمد للاحتجاز على الناجي."""

    survivor = models.OneToOneField(
        SurvivorProfile, on_delete=models.CASCADE, related_name="long_term_impact",
    )
    physical_injuries_permanent = models.TextField(
        _("إصابات جسدية دائمة"), blank=True,
    )
    chronic_illnesses = models.TextField(_("أمراض مزمنة ناتجة"), blank=True)
    disabilities = models.TextField(_("إعاقات"), blank=True)
    psychological_symptoms = models.TextField(_("الأعراض النفسية"), blank=True)
    sleep_disorders = models.BooleanField(_("اضطرابات نوم"), default=False)
    flashbacks = models.BooleanField(_("استرجاع للذكريات"), default=False)
    social_withdrawal = models.BooleanField(_("انعزال اجتماعي"), default=False)
    family_impact = models.TextField(_("الأثر على العائلة"), blank=True)
    work_impact = models.TextField(_("الأثر على القدرة على العمل"), blank=True)
    education_impact = models.TextField(_("الأثر على التعليم"), blank=True)
    financial_impact = models.TextField(_("الأثر المالي"), blank=True)
    current_medications = models.TextField(_("الأدوية الحالية"), blank=True)
    receiving_treatment = models.BooleanField(_("يتلقى علاجاً حالياً"), default=False)
    treatment_details = models.TextField(_("تفاصيل العلاج"), blank=True)

    class Meta:
        verbose_name = _("أثر طويل الأمد")
        verbose_name_plural = _("الآثار طويلة الأمد")

    def __str__(self):
        return f"الأثر طويل الأمد - {self.survivor.case_reference}"


# ============================================================
# ٨. الملاحظات المتعددة (Notes) - متابعة كل ناجٍ
# ============================================================

class SurvivorNote(models.Model):
    """ملاحظات متعددة على ملف الناجي (تتبع، متابعة، تحديثات...)."""

    class NoteType(models.TextChoices):
        GENERAL = "general", _("ملاحظة عامة")
        FOLLOW_UP = "follow_up", _("متابعة")
        REFERRAL = "referral", _("إحالة")
        MEDICAL = "medical", _("طبية/نفسية")
        LEGAL = "legal", _("قانونية")
        SECURITY = "security", _("أمنية/حماية")
        FAMILY = "family", _("متعلقة بالعائلة")
        INCONSISTENCY = "inconsistency", _("ملاحظة على اتساق الرواية")
        VERIFICATION = "verification", _("تحقق من معلومة")
        OTHER = "other", _("أخرى")

    survivor = models.ForeignKey(
        SurvivorProfile, on_delete=models.CASCADE, related_name="notes",
    )
    note_type = models.CharField(
        _("نوع الملاحظة"), max_length=20, choices=NoteType.choices,
        default=NoteType.GENERAL, db_index=True,
    )
    title = models.CharField(_("عنوان مختصر"), max_length=200, blank=True)
    content = models.TextField(_("الملاحظة"))
    is_pinned = models.BooleanField(_("مثبّتة في أعلى الملف"), default=False)
    is_confidential = models.BooleanField(
        _("سرّية (للمشرفين فقط)"), default=False,
    )
    author = models.ForeignKey(
        settings.AUTH_USER_MODEL, on_delete=models.SET_NULL, null=True,
        related_name="authored_notes", verbose_name=_("المُحرِّر"),
    )
    created_at = models.DateTimeField(auto_now_add=True, db_index=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        verbose_name = _("ملاحظة")
        verbose_name_plural = _("الملاحظات")
        ordering = ["-is_pinned", "-created_at"]

    def __str__(self):
        return f"{self.survivor.case_reference} - {self.title or self.get_note_type_display()}"


# ============================================================
# ٩. المقابلات المتعددة (Interviews) + الوسائط
# ============================================================

class Interview(models.Model):
    """مقابلة مع الناجي - يدعم تعدد المقابلات لنفس الناجي."""

    class Methodology(models.TextChoices):
        ISTANBUL = "istanbul", _("بروتوكول إسطنبول")
        SEMI_STRUCTURED = "semi_structured", _("شبه منظمة")
        NARRATIVE = "narrative", _("سردية مفتوحة")
        STRUCTURED = "structured", _("استمارة منظمة")
        FOLLOW_UP = "follow_up", _("مقابلة متابعة")
        OTHER = "other", _("أخرى")

    class Location(models.TextChoices):
        OFFICE = "office", _("في مكاتب الجمعية")
        SURVIVOR_HOME = "survivor_home", _("في منزل الناجي")
        REMOTE = "remote", _("عن بُعد (Zoom/Skype...)")
        PHONE = "phone", _("هاتفية")
        FIELD = "field", _("ميدانية أخرى")
        OTHER = "other", _("أخرى")

    survivor = models.ForeignKey(
        SurvivorProfile, on_delete=models.CASCADE, related_name="interviews",
    )
    sequence_number = models.PositiveIntegerField(
        _("رقم المقابلة"), default=1,
        help_text=_("1 = المقابلة الأولى، 2 = الثانية..."),
    )
    is_first = models.BooleanField(_("هل هذه المقابلة الأولى للناجي؟"), default=True)
    interview_date = models.DateField(_("تاريخ المقابلة"), db_index=True)
    duration_minutes = models.PositiveIntegerField(
        _("المدة بالدقائق"), null=True, blank=True,
    )

    location_type = models.CharField(
        _("نوع المكان"), max_length=20, choices=Location.choices,
        default=Location.OFFICE,
    )
    location_detail = models.CharField(
        _("تفاصيل المكان"), max_length=300, blank=True,
    )

    interviewer = models.ForeignKey(
        settings.AUTH_USER_MODEL, on_delete=models.SET_NULL, null=True,
        related_name="conducted_interviews", verbose_name=_("المحاوِر"),
    )
    note_taker = models.ForeignKey(
        settings.AUTH_USER_MODEL, on_delete=models.SET_NULL, null=True, blank=True,
        related_name="note_taken_interviews", verbose_name=_("مدوِّن الملاحظات"),
    )

    language = models.CharField(
        _("لغة المقابلة"), max_length=20,
        choices=InterviewLanguage.CHOICES, default="ar_levantine",
    )
    methodology = models.CharField(
        _("المنهجية المتّبعة"), max_length=20,
        choices=Methodology.choices, default=Methodology.ISTANBUL,
    )

    recorded = models.BooleanField(_("مسجَّلة"), default=False)
    consent_to_record = models.BooleanField(_("موافقة على التسجيل"), default=False)
    consent_to_publish_recording = models.BooleanField(
        _("موافقة على نشر التسجيل"), default=False,
    )

    summary = models.TextField(
        _("ملخص المقابلة"), blank=True,
        help_text=_("ملخص ما تم تناوله في هذه الجلسة تحديداً"),
    )
    gender_appropriate = models.BooleanField(
        _("روعيت اعتبارات النوع الاجتماعي (محاوِرة لناجية مثلاً)"), default=False,
    )
    psychological_referral_after = models.BooleanField(
        _("أُحيلت لدعم نفسي بعد المقابلة"), default=False,
    )
    notes = models.TextField(_("ملاحظات إضافية"), blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        verbose_name = _("مقابلة")
        verbose_name_plural = _("المقابلات")
        ordering = ["survivor", "sequence_number", "interview_date"]
        unique_together = [("survivor", "sequence_number")]

    def __str__(self):
        return f"مقابلة #{self.sequence_number} - {self.survivor.case_reference} ({self.interview_date})"

    @property
    def media_count(self):
        return self.media.count()


def interview_media_path(instance, filename):
    return f"survivors/interviews/{instance.interview.survivor.case_reference}/{filename}"


class InterviewMedia(models.Model):
    """وسائط متعددة لكل مقابلة (فيديوهات، صوتيات، نصوص، صور)."""

    class MediaType(models.TextChoices):
        VIDEO = "video", _("فيديو")
        AUDIO = "audio", _("صوت")
        TRANSCRIPT = "transcript", _("نص حرفي (Transcript)")
        SUMMARY_DOC = "summary_doc", _("مستند ملخص")
        PHOTO = "photo", _("صورة")
        OTHER = "other", _("أخرى")

    interview = models.ForeignKey(
        Interview, on_delete=models.CASCADE, related_name="media",
    )
    media_type = models.CharField(
        _("نوع الوسيط"), max_length=20, choices=MediaType.choices,
    )
    title = models.CharField(_("عنوان"), max_length=200)
    file = models.FileField(_("الملف"), upload_to=interview_media_path)
    file_hash_sha256 = models.CharField(
        _("بصمة SHA-256"), max_length=64, blank=True,
    )
    file_size_bytes = models.BigIntegerField(_("حجم الملف"), null=True, blank=True)
    duration_seconds = models.PositiveIntegerField(
        _("المدة بالثواني (للفيديو/الصوت)"), null=True, blank=True,
    )
    part_number = models.PositiveIntegerField(
        _("رقم الجزء (إن كانت المقابلة مقسّمة لأكثر من ملف)"), default=1,
    )
    description = models.TextField(_("وصف"), blank=True)
    uploaded_by = models.ForeignKey(
        settings.AUTH_USER_MODEL, on_delete=models.SET_NULL, null=True,
        verbose_name=_("رفعه"),
    )
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        verbose_name = _("وسيط مقابلة")
        verbose_name_plural = _("وسائط المقابلات")
        ordering = ["interview", "part_number", "media_type"]

    def __str__(self):
        return f"{self.get_media_type_display()}: {self.title} ({self.interview})"

    def save(self, *args, **kwargs):
        if self.file and not self.file_hash_sha256:
            try:
                self.file.seek(0)
                hasher = hashlib.sha256()
                for chunk in iter(lambda: self.file.read(4096), b""):
                    hasher.update(chunk)
                self.file_hash_sha256 = hasher.hexdigest()
                self.file.seek(0)
                self.file_size_bytes = self.file.size
            except Exception:
                pass
        super().save(*args, **kwargs)
