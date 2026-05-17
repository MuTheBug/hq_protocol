from django import forms
from django.utils.translation import gettext_lazy as _

from .choices import (
    Country, MaritalStatus, OccupationCategory, PoliticalActivity,
    SyrianGovernorate,
)
from .models import (
    DetentionEvent, DetentionFacility, DetentionPeriod, InformedConsent,
    Interview, InterviewMedia, MedicalAssessment, ReleaseEvent,
    SupportingDocument, SurvivorNote, SurvivorProfile, TortureMethod, Witness,
)


def _bootstrapify(form):
    for name, field in form.fields.items():
        widget = field.widget
        css = widget.attrs.get("class", "")
        if isinstance(widget, forms.CheckboxInput):
            widget.attrs["class"] = (css + " form-check-input").strip()
        elif isinstance(widget, (forms.Select, forms.SelectMultiple)):
            widget.attrs["class"] = (css + " form-select").strip()
        else:
            widget.attrs["class"] = (css + " form-control").strip()


class SurvivorProfileForm(forms.ModelForm):
    """نموذج إنشاء/تعديل الملف الأساسي - فقط حقول الهوية والاعتقال الجوهرية.

    تم نقل: معلومات الاتصال الحالية، الصور، الإحالات الطبية إلى نماذج منفصلة
    حتى لا تتكرر مع المسح الاجتماعي وأقسام أخرى.
    """

    class Meta:
        model = SurvivorProfile
        fields = (
            "case_reference", "file_classification",
            # الاسم
            "first_name", "father_name", "grandfather_name", "family_name",
            "mother_name", "alias",
            # الهوية
            "national_id", "birth_date", "birth_date_approximate",
            "birth_governorate", "birth_place_detail",
            "gender", "nationality",
            # السياق وقت الاعتقال
            "marital_status_at_detention",
            "occupation_category", "occupation_detail",
            "political_activity_category", "political_activity_detail",
            "governorate_at_detention", "address_at_detention",
        )
        widgets = {
            "birth_date": forms.DateInput(attrs={"type": "date"}),
            "address_at_detention": forms.Textarea(attrs={"rows": 2}),
            "political_activity_detail": forms.Textarea(attrs={"rows": 3}),
        }

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        _bootstrapify(self)


class SurvivorContactForm(forms.ModelForm):
    """معلومات الاتصال الحالية + قريب للتواصل."""

    class Meta:
        model = SurvivorProfile
        fields = (
            "current_phone", "current_email",
            "current_country", "current_governorate", "current_city",
            "next_of_kin_name", "next_of_kin_relation", "next_of_kin_phone",
        )

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        _bootstrapify(self)


class SurvivorPhotosForm(forms.ModelForm):
    """صور الناجي (حديثة + قبل الاعتقال)."""

    class Meta:
        model = SurvivorProfile
        fields = ("photo_recent", "photo_before_detention")

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        _bootstrapify(self)


class SurvivorReferralsForm(forms.ModelForm):
    """الإحالات الطبية والنفسية والقانونية المُقدَّمة للناجي."""

    class Meta:
        model = SurvivorProfile
        fields = (
            "medical_referral_offered", "psychological_referral_offered",
            "legal_aid_offered", "referral_notes",
        )
        widgets = {
            "referral_notes": forms.Textarea(attrs={"rows": 4}),
        }

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        _bootstrapify(self)

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        for name, field in self.fields.items():
            widget = field.widget
            css = widget.attrs.get("class", "")
            if isinstance(widget, (forms.CheckboxInput,)):
                widget.attrs["class"] = (css + " form-check-input").strip()
            elif isinstance(widget, (forms.Select,)):
                widget.attrs["class"] = (css + " form-select").strip()
            else:
                widget.attrs["class"] = (css + " form-control").strip()


class InformedConsentForm(forms.ModelForm):
    class Meta:
        model = InformedConsent
        exclude = ("survivor", "created_at", "updated_at")
        widgets = {
            "consent_date": forms.DateInput(attrs={"type": "date"}),
            "withdrawal_date": forms.DateInput(attrs={"type": "date"}),
            "withdrawal_reason": forms.Textarea(attrs={"rows": 3}),
            "notes": forms.Textarea(attrs={"rows": 3}),
        }

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        for name, field in self.fields.items():
            widget = field.widget
            css = widget.attrs.get("class", "")
            if isinstance(widget, (forms.CheckboxInput,)):
                widget.attrs["class"] = (css + " form-check-input").strip()
            elif isinstance(widget, (forms.Select,)):
                widget.attrs["class"] = (css + " form-select").strip()
            else:
                widget.attrs["class"] = (css + " form-control").strip()


class DetentionEventForm(forms.ModelForm):
    class Meta:
        model = DetentionEvent
        exclude = ("survivor",)
        widgets = {
            "detention_date": forms.DateInput(attrs={"type": "date"}),
            "circumstances": forms.Textarea(attrs={"rows": 4}),
            "arresting_personnel_details": forms.Textarea(attrs={"rows": 3}),
            "witnesses_to_arrest": forms.Textarea(attrs={"rows": 3}),
            "reason_stated": forms.Textarea(attrs={"rows": 2}),
            "notes": forms.Textarea(attrs={"rows": 2}),
        }

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        for name, field in self.fields.items():
            widget = field.widget
            css = widget.attrs.get("class", "")
            if isinstance(widget, (forms.CheckboxInput,)):
                widget.attrs["class"] = (css + " form-check-input").strip()
            elif isinstance(widget, (forms.Select,)):
                widget.attrs["class"] = (css + " form-select").strip()
            else:
                widget.attrs["class"] = (css + " form-control").strip()


class DetentionPeriodForm(forms.ModelForm):
    class Meta:
        model = DetentionPeriod
        exclude = ("survivor",)
        widgets = {
            "from_date": forms.DateInput(attrs={"type": "date"}),
            "to_date": forms.DateInput(attrs={"type": "date"}),
            "cell_description": forms.Textarea(attrs={"rows": 2}),
            "food_water": forms.Textarea(attrs={"rows": 2}),
            "sleep_conditions": forms.Textarea(attrs={"rows": 2}),
            "hygiene_conditions": forms.Textarea(attrs={"rows": 2}),
            "medical_care": forms.Textarea(attrs={"rows": 2}),
            "contact_with_outside": forms.Textarea(attrs={"rows": 2}),
            "torture_description": forms.Textarea(attrs={"rows": 5}),
            "sexual_violence_details": forms.Textarea(attrs={"rows": 4}),
            "witnessed_deaths": forms.Textarea(attrs={"rows": 4}),
            "witnessed_others": forms.Textarea(attrs={"rows": 4}),
            "notes": forms.Textarea(attrs={"rows": 2}),
        }

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        for name, field in self.fields.items():
            widget = field.widget
            css = widget.attrs.get("class", "")
            if isinstance(widget, (forms.CheckboxInput,)):
                widget.attrs["class"] = (css + " form-check-input").strip()
            elif isinstance(widget, (forms.Select, forms.SelectMultiple)):
                widget.attrs["class"] = (css + " form-select").strip()
            else:
                widget.attrs["class"] = (css + " form-control").strip()


class ReleaseEventForm(forms.ModelForm):
    class Meta:
        model = ReleaseEvent
        exclude = ("survivor",)
        widgets = {
            "release_date": forms.DateInput(attrs={"type": "date"}),
            "conditions": forms.Textarea(attrs={"rows": 3}),
            "circumstances": forms.Textarea(attrs={"rows": 4}),
        }

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        for name, field in self.fields.items():
            widget = field.widget
            css = widget.attrs.get("class", "")
            if isinstance(widget, (forms.Select,)):
                widget.attrs["class"] = (css + " form-select").strip()
            else:
                widget.attrs["class"] = (css + " form-control").strip()


class WitnessForm(forms.ModelForm):
    class Meta:
        model = Witness
        exclude = ("survivor", "documenter", "created_at")
        widgets = {
            "period_from": forms.DateInput(attrs={"type": "date"}),
            "period_to": forms.DateInput(attrs={"type": "date"}),
            "declaration_date": forms.DateInput(attrs={"type": "date"}),
            "how_recognized": forms.Textarea(attrs={"rows": 3}),
            "distinguishing_details": forms.Textarea(attrs={"rows": 3}),
            "specific_incidents": forms.Textarea(attrs={"rows": 4}),
            "full_testimony": forms.Textarea(attrs={"rows": 8}),
        }

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        for name, field in self.fields.items():
            widget = field.widget
            css = widget.attrs.get("class", "")
            if isinstance(widget, (forms.CheckboxInput,)):
                widget.attrs["class"] = (css + " form-check-input").strip()
            elif isinstance(widget, (forms.Select,)):
                widget.attrs["class"] = (css + " form-select").strip()
            else:
                widget.attrs["class"] = (css + " form-control").strip()


class SupportingDocumentForm(forms.ModelForm):
    class Meta:
        model = SupportingDocument
        exclude = (
            "survivor", "obtained_by", "file_hash_sha256",
            "file_size_bytes", "created_at",
        )
        widgets = {
            "date_obtained": forms.DateInput(attrs={"type": "date"}),
            "document_date": forms.DateInput(attrs={"type": "date"}),
            "access_date": forms.DateTimeInput(attrs={"type": "datetime-local"}),
            "description": forms.Textarea(attrs={"rows": 3}),
            "source_description": forms.Textarea(attrs={"rows": 4}),
            "forensic_analysis": forms.Textarea(attrs={"rows": 3}),
            "notes": forms.Textarea(attrs={"rows": 2}),
        }

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        for name, field in self.fields.items():
            widget = field.widget
            css = widget.attrs.get("class", "")
            if isinstance(widget, (forms.CheckboxInput,)):
                widget.attrs["class"] = (css + " form-check-input").strip()
            elif isinstance(widget, (forms.Select,)):
                widget.attrs["class"] = (css + " form-select").strip()
            else:
                widget.attrs["class"] = (css + " form-control").strip()


class MedicalAssessmentForm(forms.ModelForm):
    class Meta:
        model = MedicalAssessment
        exclude = ("survivor", "created_at")
        widgets = {
            "assessment_date": forms.DateInput(attrs={"type": "date"}),
            "physical_findings": forms.Textarea(attrs={"rows": 4}),
            "scars_description": forms.Textarea(attrs={"rows": 3}),
            "disabilities": forms.Textarea(attrs={"rows": 3}),
            "psychological_findings": forms.Textarea(attrs={"rows": 4}),
            "consistency_with_account": forms.Textarea(attrs={"rows": 3}),
            "notes": forms.Textarea(attrs={"rows": 2}),
        }

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        for name, field in self.fields.items():
            widget = field.widget
            css = widget.attrs.get("class", "")
            if isinstance(widget, (forms.CheckboxInput,)):
                widget.attrs["class"] = (css + " form-check-input").strip()
            elif isinstance(widget, (forms.Select,)):
                widget.attrs["class"] = (css + " form-select").strip()
            else:
                widget.attrs["class"] = (css + " form-control").strip()


class SurvivorSearchForm(forms.Form):
    """نموذج بحث شامل يسمح بالتصفية على جميع الحقول القابلة للفلترة."""

    NONE = [("", _("الكل"))]

    q = forms.CharField(
        required=False, label=_("بحث نصي"),
        widget=forms.TextInput(attrs={
            "class": "form-control form-control-sm",
            "placeholder": _("اسم، رقم قضية، رقم وطني، لقب..."),
        }),
    )
    classification = forms.ChoiceField(
        required=False, label=_("التصنيف"),
        choices=NONE + list(SurvivorProfile.FileClassification.choices),
        widget=forms.Select(attrs={"class": "form-select form-select-sm"}),
    )
    gender = forms.ChoiceField(
        required=False, label=_("الجنس"),
        choices=NONE + list(SurvivorProfile.Gender.choices),
        widget=forms.Select(attrs={"class": "form-select form-select-sm"}),
    )
    marital_status_at_detention = forms.ChoiceField(
        required=False, label=_("الحالة الزوجية"),
        choices=NONE + MaritalStatus.CHOICES,
        widget=forms.Select(attrs={"class": "form-select form-select-sm"}),
    )
    governorate_at_detention = forms.ChoiceField(
        required=False, label=_("محافظة الاعتقال"),
        choices=NONE + SyrianGovernorate.CHOICES,
        widget=forms.Select(attrs={"class": "form-select form-select-sm"}),
    )
    birth_governorate = forms.ChoiceField(
        required=False, label=_("محافظة الولادة"),
        choices=NONE + SyrianGovernorate.CHOICES,
        widget=forms.Select(attrs={"class": "form-select form-select-sm"}),
    )
    current_country = forms.ChoiceField(
        required=False, label=_("بلد الإقامة"),
        choices=NONE + Country.CHOICES,
        widget=forms.Select(attrs={"class": "form-select form-select-sm"}),
    )
    current_governorate = forms.ChoiceField(
        required=False, label=_("المحافظة الحالية"),
        choices=NONE + SyrianGovernorate.CHOICES,
        widget=forms.Select(attrs={"class": "form-select form-select-sm"}),
    )
    occupation_category = forms.ChoiceField(
        required=False, label=_("فئة المهنة"),
        choices=NONE + OccupationCategory.CHOICES,
        widget=forms.Select(attrs={"class": "form-select form-select-sm"}),
    )
    political_activity_category = forms.ChoiceField(
        required=False, label=_("النشاط السياسي"),
        choices=NONE + PoliticalActivity.CHOICES,
        widget=forms.Select(attrs={"class": "form-select form-select-sm"}),
    )
    facility = forms.ModelChoiceField(
        required=False, label=_("فرع/سجن"),
        queryset=DetentionFacility.objects.all(), empty_label=_("الكل"),
        widget=forms.Select(attrs={"class": "form-select form-select-sm"}),
    )
    torture_method = forms.ModelChoiceField(
        required=False, label=_("نمط تعذيب"),
        queryset=TortureMethod.objects.all(), empty_label=_("الكل"),
        widget=forms.Select(attrs={"class": "form-select form-select-sm"}),
    )
    sexual_violence_reported = forms.ChoiceField(
        required=False, label=_("بلاغ عنف جنسي"),
        choices=[("", _("الكل")), ("yes", _("نعم")), ("no", _("لا"))],
        widget=forms.Select(attrs={"class": "form-select form-select-sm"}),
    )

    # نطاقات تاريخية
    detention_from = forms.DateField(
        required=False, label=_("اعتقال من"),
        widget=forms.DateInput(attrs={"class": "form-control form-control-sm", "type": "date"}),
    )
    detention_to = forms.DateField(
        required=False, label=_("إلى"),
        widget=forms.DateInput(attrs={"class": "form-control form-control-sm", "type": "date"}),
    )
    created_from = forms.DateField(
        required=False, label=_("ملف من"),
        widget=forms.DateInput(attrs={"class": "form-control form-control-sm", "type": "date"}),
    )
    created_to = forms.DateField(
        required=False, label=_("إلى"),
        widget=forms.DateInput(attrs={"class": "form-control form-control-sm", "type": "date"}),
    )

    # نطاقات النقاط
    min_overall_score = forms.DecimalField(
        required=False, label=_("الحد الأدنى للدرجة الإجمالية"),
        min_value=0, max_value=5, max_digits=3, decimal_places=1,
        widget=forms.NumberInput(attrs={
            "class": "form-control form-control-sm", "step": "0.5",
        }),
    )

    # خصائص بوليانية مرنة
    has_consent = forms.ChoiceField(
        required=False, label=_("الموافقة المستنيرة"),
        choices=[("", _("الكل")), ("yes", _("موجودة ومكتملة")), ("no", _("ناقصة"))],
        widget=forms.Select(attrs={"class": "form-select form-select-sm"}),
    )
    consent_iiim = forms.ChoiceField(
        required=False, label=_("موافقة IIIM"),
        choices=[("", _("الكل")), ("yes", _("نعم")), ("no", _("لا"))],
        widget=forms.Select(attrs={"class": "form-select form-select-sm"}),
    )
    consent_icc = forms.ChoiceField(
        required=False, label=_("موافقة ICC"),
        choices=[("", _("الكل")), ("yes", _("نعم")), ("no", _("لا"))],
        widget=forms.Select(attrs={"class": "form-select form-select-sm"}),
    )
    has_medical_assessment = forms.ChoiceField(
        required=False, label=_("تقييم طبي"),
        choices=[("", _("الكل")), ("yes", _("متوفر")), ("istanbul", _("متوافق إسطنبول")), ("no", _("غير متوفر"))],
        widget=forms.Select(attrs={"class": "form-select form-select-sm"}),
    )
    has_video = forms.ChoiceField(
        required=False, label=_("فيديو/تسجيل"),
        choices=[("", _("الكل")), ("yes", _("متوفر")), ("no", _("غير متوفر"))],
        widget=forms.Select(attrs={"class": "form-select form-select-sm"}),
    )
    min_witnesses = forms.IntegerField(
        required=False, label=_("حد أدنى للشهود المستقلين"),
        min_value=0, widget=forms.NumberInput(attrs={"class": "form-control form-control-sm"}),
    )
    documenter = forms.IntegerField(
        required=False, widget=forms.HiddenInput(),
    )


class SurvivorNoteForm(forms.ModelForm):
    class Meta:
        model = SurvivorNote
        exclude = ("survivor", "author", "created_at", "updated_at")
        widgets = {
            "title": forms.TextInput(attrs={"class": "form-control"}),
            "content": forms.Textarea(attrs={"class": "form-control", "rows": 4}),
            "note_type": forms.Select(attrs={"class": "form-select"}),
            "is_pinned": forms.CheckboxInput(attrs={"class": "form-check-input"}),
            "is_confidential": forms.CheckboxInput(attrs={"class": "form-check-input"}),
        }


class InterviewForm(forms.ModelForm):
    class Meta:
        model = Interview
        exclude = ("survivor", "interviewer", "created_at", "updated_at")
        widgets = {
            "interview_date": forms.DateInput(attrs={"type": "date"}),
            "summary": forms.Textarea(attrs={"rows": 5}),
            "notes": forms.Textarea(attrs={"rows": 3}),
            "location_detail": forms.TextInput(),
        }

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        for name, field in self.fields.items():
            widget = field.widget
            css = widget.attrs.get("class", "")
            if isinstance(widget, forms.CheckboxInput):
                widget.attrs["class"] = (css + " form-check-input").strip()
            elif isinstance(widget, forms.Select):
                widget.attrs["class"] = (css + " form-select").strip()
            else:
                widget.attrs["class"] = (css + " form-control").strip()


class InterviewMediaForm(forms.ModelForm):
    class Meta:
        model = InterviewMedia
        exclude = (
            "interview", "uploaded_by", "file_hash_sha256",
            "file_size_bytes", "created_at",
        )
        widgets = {
            "description": forms.Textarea(attrs={"rows": 2}),
        }

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        for name, field in self.fields.items():
            widget = field.widget
            css = widget.attrs.get("class", "")
            if isinstance(widget, forms.Select):
                widget.attrs["class"] = (css + " form-select").strip()
            else:
                widget.attrs["class"] = (css + " form-control").strip()


class JSONImportForm(forms.Form):
    """نموذج لاستيراد ملف JSON يحوي بيانات الناجين."""

    file = forms.FileField(
        label=_("ملف JSON"),
        help_text=_("الملف يجب أن يكون بصيغة Django JSON (مُصدّر مسبقاً من النظام)"),
        widget=forms.FileInput(attrs={"class": "form-control", "accept": ".json"}),
    )
    merge_strategy = forms.ChoiceField(
        label=_("استراتيجية الدمج"),
        choices=[
            ("skip_existing", _("تخطّي الملفات الموجودة (آمن)")),
            ("update_existing", _("تحديث الملفات الموجودة (يطغى على الحالي)")),
        ],
        initial="skip_existing",
        widget=forms.Select(attrs={"class": "form-select"}),
    )
