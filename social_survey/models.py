"""
نماذج المسح الاجتماعي للناجين وعائلاتهم.

يستهدف توفير صورة شاملة عن وضع الناجي وعائلته بعد الإفراج
(الإسكان، التعليم، الأطفال، العمل، الدخل، الاحتياجات الإنسانية...).
"""

from django.conf import settings
from django.db import models
from django.utils.translation import gettext_lazy as _

from survivors.choices import SyrianGovernorate
from survivors.models import SurvivorProfile


# ============================================================
# ١. الأسرة (Household)
# ============================================================

class HouseholdSurvey(models.Model):
    """المسح الاجتماعي الشامل لأسرة الناجي."""

    class MaritalStatus(models.TextChoices):
        SINGLE = "single", _("أعزب/عزباء")
        MARRIED = "married", _("متزوج/ة")
        DIVORCED = "divorced", _("مطلّق/ة")
        WIDOWED = "widowed", _("أرمل/أرملة")
        SEPARATED = "separated", _("منفصل/ة")
        ENGAGED = "engaged", _("مخطوب/ة")

    class DisplacementStatus(models.TextChoices):
        NOT_DISPLACED = "not_displaced", _("لم يُهجَّر")
        INTERNALLY_DISPLACED = "idp", _("نازح داخلياً")
        REFUGEE = "refugee", _("لاجئ خارج سوريا")
        RETURNEE = "returnee", _("عائد بعد لجوء")
        ASYLUM_SEEKER = "asylum_seeker", _("طالب لجوء")

    survivor = models.OneToOneField(
        SurvivorProfile, on_delete=models.CASCADE, related_name="household_survey",
    )

    # ---- معلومات الزواج والأسرة ----
    marital_status = models.CharField(
        _("الحالة الزوجية الحالية"), max_length=20, choices=MaritalStatus.choices,
    )
    marital_status_changed_due_to_detention = models.BooleanField(
        _("هل تغيرت الحالة الزوجية بسبب الاعتقال؟"), default=False,
    )
    spouse_name = models.CharField(_("اسم الزوج/ة"), max_length=200, blank=True)
    spouse_alive = models.BooleanField(_("الزوج/ة على قيد الحياة"), default=True)
    spouse_detained_now = models.BooleanField(_("الزوج/ة محتجز/ة حالياً"), default=False)
    spouse_detained_before = models.BooleanField(_("الزوج/ة سبق اعتقاله/ها"), default=False)
    spouse_employed = models.BooleanField(_("الزوج/ة يعمل/تعمل"), default=False)
    spouse_occupation = models.CharField(_("عمل الزوج/ة"), max_length=200, blank=True)
    spouse_age = models.PositiveIntegerField(_("عمر الزوج/ة"), null=True, blank=True)

    household_size = models.PositiveIntegerField(
        _("إجمالي عدد أفراد الأسرة في المنزل"), default=1,
    )
    dependents_count = models.PositiveIntegerField(
        _("عدد المعالين كلياً"), default=0,
    )
    children_count = models.PositiveIntegerField(_("عدد الأبناء"), default=0)

    # ---- وضع التهجير ----
    displacement_status = models.CharField(
        _("وضع التهجير"), max_length=20, choices=DisplacementStatus.choices,
        default=DisplacementStatus.NOT_DISPLACED,
    )
    displacement_count = models.PositiveIntegerField(
        _("كم مرة تم التهجير؟"), default=0,
    )
    original_governorate = models.CharField(
        _("المحافظة الأصلية"), max_length=30,
        choices=SyrianGovernorate.CHOICES, blank=True, db_index=True,
    )
    current_governorate = models.CharField(
        _("المحافظة الحالية (داخل سوريا)"), max_length=30,
        choices=SyrianGovernorate.CHOICES, blank=True, db_index=True,
    )

    # ---- معلومات المسح ----
    surveyor = models.ForeignKey(
        settings.AUTH_USER_MODEL, on_delete=models.SET_NULL, null=True,
        related_name="conducted_surveys", verbose_name=_("الباحث الاجتماعي"),
    )
    survey_date = models.DateField(_("تاريخ المسح"))
    survey_location = models.CharField(_("مكان المسح"), max_length=200, blank=True)
    survey_notes = models.TextField(_("ملاحظات الباحث"), blank=True)
    consent_to_survey = models.BooleanField(
        _("موافقة الناجي على المسح الاجتماعي"), default=False,
    )

    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        verbose_name = _("مسح اجتماعي للأسرة")
        verbose_name_plural = _("المسوحات الاجتماعية")
        ordering = ["-survey_date"]

    def __str__(self):
        return f"مسح أسرة {self.survivor.case_reference} - {self.survey_date}"


# ============================================================
# ٢. الأبناء (Children)
# ============================================================

class Child(models.Model):
    """ابن/ابنة الناجي - مع معلومات تعليمه ووضعه الصحي والعمل."""

    class Gender(models.TextChoices):
        MALE = "male", _("ذكر")
        FEMALE = "female", _("أنثى")

    class SchoolStage(models.TextChoices):
        PRESCHOOL = "preschool", _("روضة")
        PRIMARY = "primary", _("ابتدائي")
        PREPARATORY = "preparatory", _("إعدادي")
        SECONDARY = "secondary", _("ثانوي")
        VOCATIONAL = "vocational", _("مهني/تقني")
        UNIVERSITY = "university", _("جامعي")
        POSTGRADUATE = "postgraduate", _("دراسات عليا")
        NOT_STARTED = "not_started", _("لم يبدأ الدراسة بعد")
        NEVER_ATTENDED = "never_attended", _("لم يلتحق بالمدرسة قطّ")

    class WorkType(models.TextChoices):
        STUDENT_ONLY = "student", _("طالب فقط")
        HELPS_FAMILY = "helps_family", _("يساعد الأسرة")
        CHILD_LABOR = "child_labor", _("عمالة أطفال")
        STREET_WORK = "street_work", _("عمل في الشارع")
        APPRENTICE = "apprentice", _("متدرّب/صبي مهنة")
        REGULAR_JOB = "regular_job", _("عمل منتظم")
        NONE = "none", _("لا يعمل")

    household = models.ForeignKey(
        HouseholdSurvey, on_delete=models.CASCADE, related_name="children",
    )
    name = models.CharField(_("اسم الابن/الابنة"), max_length=200)
    gender = models.CharField(_("الجنس"), max_length=10, choices=Gender.choices)
    birth_date = models.DateField(_("تاريخ الميلاد"), null=True, blank=True)
    age = models.PositiveIntegerField(
        _("العمر"), null=True, blank=True,
        help_text=_("يُستخدم في حال عدم توفر تاريخ ميلاد دقيق"),
    )

    # ---- التعليم ----
    is_in_school = models.BooleanField(_("هل يداوم في المدرسة؟"), default=True)
    current_stage = models.CharField(
        _("المرحلة الدراسية الحالية"), max_length=20, choices=SchoolStage.choices,
        default=SchoolStage.NOT_STARTED,
    )
    current_grade = models.CharField(_("الصف الحالي"), max_length=50, blank=True)
    school_name = models.CharField(_("اسم المدرسة"), max_length=200, blank=True)
    dropped_out = models.BooleanField(_("هل ترك الدراسة؟"), default=False)
    dropout_grade = models.CharField(
        _("الصف الذي تركها عنده"), max_length=50, blank=True,
    )
    dropout_year = models.PositiveIntegerField(
        _("سنة ترك الدراسة"), null=True, blank=True,
    )
    dropout_due_to_father_detention = models.BooleanField(
        _("ترك بسبب اعتقال الأب/الأم"), default=False,
    )
    dropout_reason = models.TextField(_("سبب ترك الدراسة"), blank=True)
    wants_to_resume_education = models.BooleanField(
        _("يرغب باستئناف التعليم"), default=False,
    )

    # ---- الصحة ----
    has_disability = models.BooleanField(_("لديه إعاقة"), default=False)
    disability_description = models.TextField(_("وصف الإعاقة"), blank=True)
    has_chronic_illness = models.BooleanField(_("لديه مرض مزمن"), default=False)
    chronic_illness_description = models.TextField(_("وصف المرض"), blank=True)
    psychological_issues = models.BooleanField(
        _("معاناة نفسية ملحوظة"), default=False,
    )
    psychological_notes = models.TextField(
        _("ملاحظات نفسية"), blank=True,
        help_text=_("أعراض، تأثر باعتقال الوالد، إلخ"),
    )

    # ---- العمل ----
    work_status = models.CharField(
        _("وضع العمل"), max_length=20, choices=WorkType.choices,
        default=WorkType.STUDENT_ONLY,
    )
    work_description = models.CharField(
        _("وصف العمل (إن وُجد)"), max_length=200, blank=True,
    )
    work_started_due_to_detention = models.BooleanField(
        _("بدأ العمل بسبب اعتقال الوالد"), default=False,
    )

    notes = models.TextField(_("ملاحظات"), blank=True)

    class Meta:
        verbose_name = _("ابن/ابنة")
        verbose_name_plural = _("الأبناء")
        ordering = ["birth_date", "name"]

    def __str__(self):
        return f"{self.name} ({self.household.survivor.case_reference})"


# ============================================================
# ٣. السكن (Housing)
# ============================================================

class HousingInfo(models.Model):
    """معلومات السكن الحالية للأسرة."""

    class HousingType(models.TextChoices):
        OWNED = "owned", _("ملك خاص")
        RENTED = "rented", _("إيجار")
        WITH_FAMILY = "with_family", _("مع أهل/أقارب")
        SHARED = "shared", _("سكن مشترك")
        IDP_CAMP = "idp_camp", _("مخيم نازحين")
        REFUGEE_CAMP = "refugee_camp", _("مخيم لاجئين")
        SHELTER = "shelter", _("مأوى/مركز إيواء")
        DAMAGED = "damaged", _("منزل متضرر")
        DESTROYED_ORIGINAL = "destroyed", _("المنزل الأصلي مدمَّر")
        HOMELESS = "homeless", _("بلا مأوى")
        OTHER = "other", _("أخرى")

    class Condition(models.TextChoices):
        GOOD = "good", _("جيدة")
        ACCEPTABLE = "acceptable", _("مقبولة")
        POOR = "poor", _("سيئة")
        VERY_POOR = "very_poor", _("سيئة جداً/غير صالحة للسكن")

    class Currency(models.TextChoices):
        SYP = "SYP", _("ليرة سورية")
        USD = "USD", _("دولار أميركي")
        TRY = "TRY", _("ليرة تركية")
        EUR = "EUR", _("يورو")
        OTHER = "other", _("أخرى")

    household = models.OneToOneField(
        HouseholdSurvey, on_delete=models.CASCADE, related_name="housing",
    )
    housing_type = models.CharField(
        _("نوع السكن"), max_length=20, choices=HousingType.choices,
    )

    # الإيجار
    rent_amount = models.DecimalField(
        _("قيمة الإيجار الشهري"), max_digits=12, decimal_places=2,
        null=True, blank=True,
    )
    rent_currency = models.CharField(
        _("عملة الإيجار"), max_length=10, choices=Currency.choices,
        default=Currency.SYP,
    )
    rent_overdue = models.BooleanField(_("متأخرات إيجار"), default=False)
    rent_overdue_months = models.PositiveIntegerField(
        _("عدد أشهر التأخر"), default=0,
    )
    threatened_with_eviction = models.BooleanField(
        _("مهدَّد بالإخراج من المنزل"), default=False,
    )

    # وصف المسكن
    rooms_count = models.PositiveIntegerField(_("عدد الغرف"), default=1)
    residents_count = models.PositiveIntegerField(_("عدد القاطنين"), default=1)
    condition = models.CharField(
        _("الحالة العامة للسكن"), max_length=20, choices=Condition.choices,
        default=Condition.ACCEPTABLE,
    )

    # المرافق
    has_electricity = models.BooleanField(_("كهرباء"), default=False)
    electricity_hours_per_day = models.PositiveIntegerField(
        _("ساعات الكهرباء يومياً"), null=True, blank=True,
    )
    has_water = models.BooleanField(_("ماء"), default=False)
    has_heating = models.BooleanField(_("تدفئة"), default=False)
    has_sanitation = models.BooleanField(_("صرف صحي"), default=False)
    has_internet = models.BooleanField(_("إنترنت"), default=False)

    # الموقع
    address = models.TextField(_("العنوان"), blank=True)
    governorate = models.CharField(
        _("المحافظة"), max_length=30,
        choices=SyrianGovernorate.CHOICES, blank=True, db_index=True,
    )
    city = models.CharField(_("المدينة/البلدة"), max_length=100, blank=True)
    neighborhood = models.CharField(_("الحي"), max_length=100, blank=True)

    # ملكية أصلية
    owned_original_home_before = models.BooleanField(
        _("هل كان يملك منزلاً قبل الاعتقال/التهجير؟"), default=False,
    )
    original_home_status = models.TextField(
        _("وضع المنزل الأصلي حالياً"), blank=True,
    )
    property_confiscated = models.BooleanField(
        _("هل تمت مصادرة ممتلكاته؟"), default=False,
    )
    confiscation_details = models.TextField(_("تفاصيل المصادرة"), blank=True)

    notes = models.TextField(_("ملاحظات"), blank=True)

    class Meta:
        verbose_name = _("سكن")
        verbose_name_plural = _("معلومات السكن")

    def __str__(self):
        return f"سكن {self.household.survivor.case_reference} - {self.get_housing_type_display()}"


# ============================================================
# ٤. التعليم والعمل والدخل
# ============================================================

class EducationStatus(models.Model):
    """وضع الناجي التعليمي قبل وبعد الاعتقال."""

    class Level(models.TextChoices):
        ILLITERATE = "illiterate", _("أمي")
        READS_WRITES = "reads_writes", _("يقرأ ويكتب فقط")
        PRIMARY = "primary", _("ابتدائي")
        PREPARATORY = "preparatory", _("إعدادي")
        SECONDARY = "secondary", _("ثانوي/بكالوريا")
        VOCATIONAL = "vocational", _("معهد متوسط/مهني")
        BACHELOR = "bachelor", _("إجازة جامعية")
        MASTER = "master", _("ماجستير")
        PHD = "phd", _("دكتوراه")

    survivor = models.OneToOneField(
        SurvivorProfile, on_delete=models.CASCADE, related_name="education",
    )
    highest_level_before_detention = models.CharField(
        _("أعلى مستوى دراسي قبل الاعتقال"), max_length=20, choices=Level.choices,
    )
    highest_level_now = models.CharField(
        _("أعلى مستوى دراسي حالياً"), max_length=20, choices=Level.choices,
    )
    studies_interrupted_by_detention = models.BooleanField(
        _("هل انقطع عن الدراسة بسبب الاعتقال؟"), default=False,
    )
    field_of_study = models.CharField(_("التخصص"), max_length=200, blank=True)
    institution = models.CharField(_("المؤسسة التعليمية"), max_length=200, blank=True)

    is_currently_studying = models.BooleanField(
        _("هل يدرس حالياً؟"), default=False,
    )
    current_program = models.CharField(
        _("البرنامج/المرحلة الحالية"), max_length=200, blank=True,
    )
    wants_to_resume = models.BooleanField(_("يرغب باستئناف التعليم"), default=False)
    obstacles_to_education = models.TextField(
        _("عقبات تحول دون استئناف التعليم"), blank=True,
    )

    languages_spoken = models.CharField(
        _("اللغات التي يجيدها"), max_length=300, blank=True,
    )
    has_certificates = models.BooleanField(_("لديه شهادات معتمدة"), default=False)
    certificates_details = models.TextField(_("تفاصيل الشهادات"), blank=True)
    certificates_lost = models.BooleanField(
        _("فقد شهاداته بسبب الاعتقال/التهجير"), default=False,
    )

    class Meta:
        verbose_name = _("وضع تعليمي")
        verbose_name_plural = _("الأوضاع التعليمية")

    def __str__(self):
        return f"تعليم {self.survivor.case_reference}"


class EmploymentInfo(models.Model):
    """وضع الناجي المهني والدخل."""

    class EmploymentStatus(models.TextChoices):
        EMPLOYED_FORMAL = "employed_formal", _("عمل رسمي")
        EMPLOYED_INFORMAL = "employed_informal", _("عمل غير رسمي")
        SELF_EMPLOYED = "self_employed", _("عمل حر")
        DAILY_LABOR = "daily_labor", _("عمل بالمياومة")
        UNEMPLOYED_SEEKING = "unemployed_seeking", _("عاطل يبحث عن عمل")
        UNEMPLOYED_NOT_SEEKING = "unemployed_not_seeking", _("عاطل لا يبحث")
        UNABLE_TO_WORK = "unable_to_work", _("غير قادر على العمل (لأسباب صحية)")
        STUDENT = "student", _("طالب")
        RETIRED = "retired", _("متقاعد")
        HOUSEWIFE = "housewife", _("ربّة منزل")

    class Currency(models.TextChoices):
        SYP = "SYP", _("ليرة سورية")
        USD = "USD", _("دولار أميركي")
        TRY = "TRY", _("ليرة تركية")
        EUR = "EUR", _("يورو")
        OTHER = "other", _("أخرى")

    survivor = models.OneToOneField(
        SurvivorProfile, on_delete=models.CASCADE, related_name="employment",
    )
    status = models.CharField(
        _("وضع العمل الحالي"), max_length=30, choices=EmploymentStatus.choices,
    )
    # ملاحظة: المهنة وقت الاعتقال موجودة في SurvivorProfile.occupation_category
    # هنا نوثّق فقط المهنة الحالية وفرق الوضع
    current_occupation = models.CharField(
        _("المهنة الحالية"), max_length=200, blank=True,
    )
    same_as_before = models.BooleanField(
        _("هل عاد لنفس المهنة السابقة؟"), default=False,
    )
    unable_due_to_health = models.BooleanField(
        _("غير قادر على العمل لأسباب صحية ناتجة عن الاحتجاز"), default=False,
    )
    unable_due_to_legal = models.BooleanField(
        _("غير قادر على العمل لأسباب قانونية (مطلوب أمنياً، فقدان وثائق...)"),
        default=False,
    )

    monthly_income = models.DecimalField(
        _("الدخل الشهري التقريبي"), max_digits=12, decimal_places=2,
        null=True, blank=True,
    )
    income_currency = models.CharField(
        _("العملة"), max_length=10, choices=Currency.choices, default=Currency.SYP,
    )
    income_covers_basic_needs = models.BooleanField(
        _("الدخل يغطي الاحتياجات الأساسية"), default=False,
    )

    # مصادر الدخل
    has_salary = models.BooleanField(_("راتب"), default=False)
    has_business_income = models.BooleanField(_("دخل من عمل تجاري"), default=False)
    has_pension = models.BooleanField(_("معاش تقاعدي"), default=False)
    has_remittance = models.BooleanField(_("حوالات من الخارج"), default=False)
    has_humanitarian_aid = models.BooleanField(_("مساعدات إنسانية"), default=False)
    has_family_support = models.BooleanField(_("مساعدات من الأهل"), default=False)
    other_income_sources = models.TextField(_("مصادر دخل أخرى"), blank=True)

    work_hours_per_week = models.PositiveIntegerField(
        _("ساعات العمل الأسبوعية"), null=True, blank=True,
    )
    notes = models.TextField(_("ملاحظات"), blank=True)

    class Meta:
        verbose_name = _("وضع مهني ودخل")
        verbose_name_plural = _("الأوضاع المهنية والدخل")

    def __str__(self):
        return f"عمل {self.survivor.case_reference} - {self.get_status_display()}"


# ============================================================
# ٥. الصحة والاحتياجات
# ============================================================

class HealthAccess(models.Model):
    """وصول الأسرة للرعاية الصحية."""

    class FoodSecurity(models.TextChoices):
        GOOD = "good", _("أمن غذائي جيد")
        MODERATE = "moderate", _("متوسط")
        POOR = "poor", _("ضعيف")
        SEVERE = "severe", _("انعدام أمن غذائي حاد")

    household = models.OneToOneField(
        HouseholdSurvey, on_delete=models.CASCADE, related_name="health_access",
    )
    has_health_insurance = models.BooleanField(_("لديه تأمين صحي"), default=False)
    insurance_type = models.CharField(_("نوع التأمين"), max_length=100, blank=True)
    access_to_primary_care = models.BooleanField(
        _("وصول للرعاية الأولية"), default=False,
    )
    access_to_specialized_care = models.BooleanField(
        _("وصول للرعاية المتخصصة"), default=False,
    )
    distance_to_health_facility_km = models.DecimalField(
        _("بُعد أقرب مرفق صحي (كم)"), max_digits=6, decimal_places=2,
        null=True, blank=True,
    )

    chronic_illnesses_in_family = models.TextField(
        _("الأمراض المزمنة في الأسرة"), blank=True,
    )
    family_members_with_disability = models.PositiveIntegerField(
        _("عدد ذوي الإعاقة في الأسرة"), default=0,
    )
    psychological_support_received = models.BooleanField(
        _("يتلقى دعماً نفسياً"), default=False,
    )
    psychological_support_provider = models.CharField(
        _("جهة الدعم النفسي"), max_length=200, blank=True,
    )

    medications_unaffordable = models.BooleanField(
        _("لا يستطيع تأمين الأدوية"), default=False,
    )
    unmet_medical_needs = models.TextField(
        _("احتياجات طبية غير مُلبّاة"), blank=True,
    )

    food_security = models.CharField(
        _("الأمن الغذائي"), max_length=20, choices=FoodSecurity.choices,
        default=FoodSecurity.MODERATE,
    )
    meals_per_day = models.PositiveIntegerField(
        _("وجبات يومية"), default=3,
    )

    notes = models.TextField(_("ملاحظات"), blank=True)

    class Meta:
        verbose_name = _("وصول للصحة")
        verbose_name_plural = _("بيانات الوصول للصحة")

    def __str__(self):
        return f"صحة {self.household.survivor.case_reference}"


class NeedsAssessment(models.Model):
    """تقييم احتياجات الأسرة (للتخطيط البرامجي والاستجابة الإنسانية)."""

    class Priority(models.TextChoices):
        CRITICAL = "critical", _("حرج/طارئ")
        HIGH = "high", _("عالي")
        MEDIUM = "medium", _("متوسط")
        LOW = "low", _("منخفض")
        NONE = "none", _("لا حاجة")

    household = models.OneToOneField(
        HouseholdSurvey, on_delete=models.CASCADE, related_name="needs",
    )

    financial_aid_priority = models.CharField(
        _("مساعدة مالية"), max_length=20, choices=Priority.choices,
        default=Priority.NONE,
    )
    food_aid_priority = models.CharField(
        _("مساعدة غذائية"), max_length=20, choices=Priority.choices,
        default=Priority.NONE,
    )
    housing_aid_priority = models.CharField(
        _("مساعدة إسكان"), max_length=20, choices=Priority.choices,
        default=Priority.NONE,
    )
    medical_aid_priority = models.CharField(
        _("مساعدة طبية"), max_length=20, choices=Priority.choices,
        default=Priority.NONE,
    )
    psychological_support_priority = models.CharField(
        _("دعم نفسي"), max_length=20, choices=Priority.choices,
        default=Priority.NONE,
    )
    legal_aid_priority = models.CharField(
        _("مساعدة قانونية"), max_length=20, choices=Priority.choices,
        default=Priority.NONE,
    )
    education_aid_priority = models.CharField(
        _("دعم تعليمي للأبناء"), max_length=20, choices=Priority.choices,
        default=Priority.NONE,
    )
    vocational_training_priority = models.CharField(
        _("تدريب مهني"), max_length=20, choices=Priority.choices,
        default=Priority.NONE,
    )
    documents_recovery_priority = models.CharField(
        _("استرداد وثائق رسمية"), max_length=20, choices=Priority.choices,
        default=Priority.NONE,
    )

    # تفاصيل قانونية
    needs_id_card = models.BooleanField(_("يحتاج هوية شخصية"), default=False)
    needs_family_booklet = models.BooleanField(_("يحتاج دفتر عائلة"), default=False)
    needs_passport = models.BooleanField(_("يحتاج جواز سفر"), default=False)
    needs_birth_certificate = models.BooleanField(
        _("يحتاج شهادة ميلاد"), default=False,
    )
    needs_marriage_certificate = models.BooleanField(
        _("يحتاج وثيقة زواج"), default=False,
    )
    needs_security_clearance = models.BooleanField(
        _("يحتاج إخراج قيد/تسوية وضع أمني"), default=False,
    )

    additional_needs = models.TextField(_("احتياجات أخرى"), blank=True)
    barriers_to_aid = models.TextField(
        _("عقبات الوصول للمساعدات"), blank=True,
    )

    assessed_by = models.ForeignKey(
        settings.AUTH_USER_MODEL, on_delete=models.SET_NULL, null=True,
        verbose_name=_("المُقيِّم"),
    )
    assessment_date = models.DateField(_("تاريخ التقييم"))
    follow_up_required = models.BooleanField(_("يحتاج متابعة"), default=True)
    follow_up_date = models.DateField(_("تاريخ المتابعة"), null=True, blank=True)
    notes = models.TextField(_("ملاحظات"), blank=True)

    class Meta:
        verbose_name = _("تقييم احتياجات")
        verbose_name_plural = _("تقييمات الاحتياجات")
        ordering = ["-assessment_date"]

    def __str__(self):
        return f"احتياجات {self.household.survivor.case_reference}"
