import mimetypes
import os

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

# ============================================================
# قواعد التحقق من ملفات الرفع - حماية من رفع ملفات خبيثة
# ============================================================

# الحدود (بايت)
MAX_PDF_BYTES = 20 * 1024 * 1024     # 20MB
MAX_IMAGE_BYTES = 10 * 1024 * 1024    # 10MB
MAX_AUDIO_BYTES = 50 * 1024 * 1024    # 50MB
MAX_VIDEO_BYTES = 200 * 1024 * 1024   # 200MB
MAX_DOC_BYTES = 30 * 1024 * 1024      # 30MB - وثائق Word/Excel

ALLOWED_DOC_EXTS = {
    ".pdf", ".jpg", ".jpeg", ".png", ".webp", ".gif", ".heic",
    ".doc", ".docx", ".xls", ".xlsx", ".odt", ".txt",
    ".mp4", ".mov", ".webm", ".mp3", ".m4a", ".ogg", ".wav",
}
ALLOWED_MEDIA_EXTS = {
    ".mp4", ".mov", ".webm", ".mkv", ".avi",
    ".mp3", ".m4a", ".ogg", ".wav", ".aac",
    ".pdf", ".txt", ".docx", ".odt",
    ".jpg", ".jpeg", ".png", ".webp",
}
DANGEROUS_EXTS = {
    ".exe", ".bat", ".cmd", ".sh", ".ps1", ".vbs", ".js",
    ".jar", ".scr", ".com", ".msi", ".app", ".apk",
    ".php", ".py", ".pl", ".rb", ".lua",
    ".html", ".htm", ".svg",  # ممكن تحتوي JS
}


def _validate_upload(uploaded, allowed_exts, max_bytes, kind="ملف"):
    """فحص امتداد + حجم + رفض الامتدادات الخطرة. يُستخدم من clean_file()."""
    if not uploaded:
        return uploaded
    name = (uploaded.name or "").lower()
    ext = os.path.splitext(name)[1]

    if ext in DANGEROUS_EXTS:
        raise forms.ValidationError(
            _("نوع الملف '%(e)s' غير مسموح لأسباب أمنية.") % {"e": ext},
        )
    if ext not in allowed_exts:
        raise forms.ValidationError(
            _("امتداد '%(e)s' غير مسموح. الامتدادات المسموحة: %(a)s")
            % {"e": ext, "a": ", ".join(sorted(allowed_exts))},
        )
    if uploaded.size > max_bytes:
        raise forms.ValidationError(
            _("الملف أكبر من الحد المسموح (%(mb)d ميغا). حجمه: %(s)d ميغا.")
            % {"mb": max_bytes // (1024*1024), "s": uploaded.size // (1024*1024)},
        )
    return uploaded


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

    _IMG_EXTS = {".jpg", ".jpeg", ".png", ".webp", ".heic", ".gif"}

    class Meta:
        model = SurvivorProfile
        fields = ("photo_recent", "photo_before_detention")

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        _bootstrapify(self)

    def clean_photo_recent(self):
        photo = self.cleaned_data.get("photo_recent")
        return _validate_upload(photo, self._IMG_EXTS, MAX_IMAGE_BYTES, "صورة") if photo else photo

    def clean_photo_before_detention(self):
        photo = self.cleaned_data.get("photo_before_detention")
        return _validate_upload(photo, self._IMG_EXTS, MAX_IMAGE_BYTES, "صورة") if photo else photo


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

    def clean_file(self):
        uploaded = self.cleaned_data.get("file")
        return _validate_upload(uploaded, ALLOWED_DOC_EXTS, MAX_DOC_BYTES, "وثيقة")


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

    def clean_file(self):
        uploaded = self.cleaned_data.get("file")
        media_type = self.cleaned_data.get("media_type")
        # حدود مختلفة حسب نوع الوسيط
        if media_type == "video":
            max_bytes = MAX_VIDEO_BYTES
        elif media_type == "audio":
            max_bytes = MAX_AUDIO_BYTES
        elif media_type == "photo":
            max_bytes = MAX_IMAGE_BYTES
        else:
            max_bytes = MAX_DOC_BYTES
        return _validate_upload(uploaded, ALLOWED_MEDIA_EXTS, max_bytes, "وسيط مقابلة")


class JSONImportForm(forms.Form):
    """نموذج لاستيراد ملف JSON يحوي بيانات الناجين."""

    MAX_FILE_BYTES = 100 * 1024 * 1024  # 100MB

    file = forms.FileField(
        label=_("ملف JSON"),
        help_text=_("الملف يجب أن يكون بصيغة Django JSON (مُصدّر مسبقاً من النظام)"),
        widget=forms.FileInput(attrs={"class": "form-control", "accept": ".json"}),
    )
    merge_strategy = forms.ChoiceField(
        label=_("استراتيجية الدمج"),
        choices=[
            ("skip_existing", _("تخطّي الملفات الموجودة (آمن)")),
            ("update_existing", _("تحديث الملفات الموجودة - بسجل تدقيق")),
        ],
        initial="skip_existing",
        widget=forms.Select(attrs={"class": "form-select"}),
    )

    def clean_file(self):
        import json as _json
        uploaded = self.cleaned_data["file"]
        # 1. حجم
        if uploaded.size > self.MAX_FILE_BYTES:
            raise forms.ValidationError(
                _("الملف أكبر من الحد المسموح (100 ميجا)."),
            )
        # 2. صيغة JSON صحيحة و list من dicts بشكل Django dumpdata
        try:
            uploaded.seek(0)
            content = uploaded.read().decode("utf-8")
            data = _json.loads(content)
        except UnicodeDecodeError:
            raise forms.ValidationError(_("الملف ليس UTF-8 صالحاً."))
        except _json.JSONDecodeError as e:
            raise forms.ValidationError(_("صيغة JSON غير صالحة: %(err)s") % {"err": str(e)})

        if not isinstance(data, list):
            raise forms.ValidationError(_("الملف يجب أن يكون قائمة (list) من السجلات."))

        # 3. كل عنصر يجب أن يحوي model + pk + fields
        allowed_models = {
            "survivors.detentionfacility", "survivors.torturemethod",
            "survivors.survivorprofile", "survivors.informedconsent",
            "survivors.detentionevent", "survivors.detentionperiod",
            "survivors.releaseevent", "survivors.witness",
            "survivors.supportingdocument", "survivors.medicalassessment",
            "survivors.longtermimpact", "survivors.survivornote",
            "survivors.interview", "survivors.interviewmedia",
            # AuditLog و ChainOfCustodyLog محمية - لا تُستورَد
        }
        for i, item in enumerate(data):
            if not isinstance(item, dict) or "model" not in item or "fields" not in item:
                raise forms.ValidationError(
                    _("العنصر #%(i)d ليس بصيغة Django dumpdata.") % {"i": i + 1},
                )
            model = (item.get("model") or "").lower()
            if model not in allowed_models:
                raise forms.ValidationError(
                    _("النموذج '%(m)s' غير مسموح للاستيراد (للحماية).")
                    % {"m": item.get("model")},
                )

        uploaded.seek(0)
        return uploaded
