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
    governorate = models.CharField(_("المحافظة"), max_length=100, blank=True)
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

class SurvivorProfile(models.Model):
    """ملف ناجٍ كامل - يطابق الحد الأدنى لمعلومات IIIM."""

    class Status(models.TextChoices):
        ALIVE_RELEASED = "alive_released", _("ناجٍ مُفرج عنه")
        STILL_DETAINED = "still_detained", _("لا يزال محتجزاً")
        MISSING = "missing", _("مفقود/مغيّب قسرياً")
        DECEASED_CUSTODY = "deceased_custody", _("توفي في الاحتجاز")
        DECEASED_AFTER = "deceased_after", _("توفي بعد الإفراج")

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
    )
    birth_date = models.DateField(_("تاريخ الميلاد"), null=True, blank=True)
    birth_date_approximate = models.BooleanField(
        _("تاريخ الميلاد تقريبي"), default=False,
    )
    birth_place = models.CharField(_("مكان الولادة"), max_length=200, blank=True)
    gender = models.CharField(_("الجنس"), max_length=10, choices=Gender.choices)
    nationality = models.CharField(_("الجنسية"), max_length=100, default="سورية")
    marital_status_at_detention = models.CharField(
        _("الحالة الزوجية وقت الاعتقال"), max_length=50, blank=True,
    )

    # ---- وقت الاعتقال ----
    address_at_detention = models.TextField(_("عنوان السكن وقت الاعتقال"), blank=True)
    governorate_at_detention = models.CharField(
        _("المحافظة وقت الاعتقال"), max_length=100, blank=True,
    )
    occupation_at_detention = models.CharField(
        _("العمل/الدراسة وقت الاعتقال"), max_length=200, blank=True,
    )
    political_affiliation = models.TextField(
        _("الانتماء/النشاط السياسي (إن وُجد)"), blank=True,
    )

    # ---- معلومات اتصال حالية ----
    current_phone = models.CharField(_("رقم الهاتف الحالي"), max_length=30, blank=True)
    current_email = models.EmailField(_("البريد الإلكتروني الحالي"), blank=True)
    current_country = models.CharField(_("بلد الإقامة الحالي"), max_length=100, blank=True)
    current_city = models.CharField(_("المدينة الحالية"), max_length=100, blank=True)
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

    # ---- الحالة العامة ----
    status = models.CharField(
        _("الحالة الراهنة"), max_length=30, choices=Status.choices,
        default=Status.ALIVE_RELEASED,
    )
    death_date = models.DateField(_("تاريخ الوفاة (إن وُجد)"), null=True, blank=True)
    death_circumstances = models.TextField(_("ظروف الوفاة"), blank=True)

    # ---- التصنيف الداخلي ----
    file_classification = models.CharField(
        _("تصنيف الملف"), max_length=10, choices=FileClassification.choices,
        default=FileClassification.DRAFT,
    )
    reliability_score = models.PositiveSmallIntegerField(
        _("درجة الموثوقية (1-5)"), default=0,
        help_text=_("اتساق الرواية الداخلي وتماسك الناجي"),
    )
    corroboration_score = models.PositiveSmallIntegerField(
        _("درجة التحقق المتقاطع (1-5)"), default=0,
        help_text=_("عدد وأنواع الأدلة المؤيِّدة (شهود، وثائق، أدلة طبية...)"),
    )
    completeness_score = models.PositiveSmallIntegerField(
        _("درجة الاكتمال (1-5)"), default=0,
    )

    # ---- بيانات وصفية ----
    documenter = models.ForeignKey(
        settings.AUTH_USER_MODEL, on_delete=models.SET_NULL, null=True,
        related_name="documented_survivors", verbose_name=_("الموثّق المسؤول"),
    )
    interview_date = models.DateField(_("تاريخ المقابلة"), null=True, blank=True)
    interview_location = models.CharField(
        _("مكان المقابلة"), max_length=200, blank=True,
    )
    interview_language = models.CharField(
        _("لغة المقابلة"), max_length=50, default="العربية",
    )
    interview_recorded = models.BooleanField(
        _("هل تم تسجيل المقابلة (صوت/فيديو)؟"), default=False,
    )
    interview_recording_consent = models.BooleanField(
        _("موافقة على التسجيل"), default=False,
    )
    is_first_interview = models.BooleanField(
        _("هل هذه أول مقابلة للناجي؟"), default=True,
        help_text=_("الـIIIM تتجنب إعادة مقابلة الناجين لتجنب إعادة الصدمة"),
    )
    previous_interviews_with = models.TextField(
        _("مقابلات سابقة أُجريت معه (المنظمات والتواريخ)"), blank=True,
    )

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

    created_at = models.DateTimeField(auto_now_add=True)
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
    def total_documents(self):
        return self.documents.count()

    @property
    def overall_score(self):
        scores = [self.reliability_score, self.corroboration_score, self.completeness_score]
        if not any(scores):
            return 0
        return round(sum(scores) / 3, 1)


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
    governorate = models.CharField(_("المحافظة"), max_length=100, blank=True)
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
    return f"survivors/documents/{instance.survivor.case_reference}/{filename}"


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

    consistency_with_account = models.TextField(
        _("مدى توافق النتائج مع رواية الناجي"), blank=True,
        help_text=_("بمصطلحات بروتوكول إسطنبول: highly consistent / consistent / typical / not consistent"),
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
