from django import forms
from django.utils.translation import gettext_lazy as _

from .models import (
    DetentionEvent, DetentionPeriod, InformedConsent, MedicalAssessment,
    ReleaseEvent, SupportingDocument, SurvivorProfile, Witness,
)


class SurvivorProfileForm(forms.ModelForm):
    class Meta:
        model = SurvivorProfile
        exclude = ("case_uid", "created_at", "updated_at", "documenter")
        widgets = {
            "birth_date": forms.DateInput(attrs={"type": "date"}),
            "interview_date": forms.DateInput(attrs={"type": "date"}),
            "death_date": forms.DateInput(attrs={"type": "date"}),
            "address_at_detention": forms.Textarea(attrs={"rows": 2}),
            "political_affiliation": forms.Textarea(attrs={"rows": 3}),
            "death_circumstances": forms.Textarea(attrs={"rows": 3}),
            "previous_interviews_with": forms.Textarea(attrs={"rows": 3}),
            "referral_notes": forms.Textarea(attrs={"rows": 3}),
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
    q = forms.CharField(
        required=False, label=_("بحث"),
        widget=forms.TextInput(attrs={
            "class": "form-control",
            "placeholder": _("اسم، رقم قضية، رقم وطني..."),
        }),
    )
    status = forms.ChoiceField(
        required=False, label=_("الحالة"),
        choices=[("", _("الكل"))] + list(SurvivorProfile.Status.choices),
        widget=forms.Select(attrs={"class": "form-select"}),
    )
    classification = forms.ChoiceField(
        required=False, label=_("التصنيف"),
        choices=[("", _("الكل"))] + list(SurvivorProfile.FileClassification.choices),
        widget=forms.Select(attrs={"class": "form-select"}),
    )
    gender = forms.ChoiceField(
        required=False, label=_("الجنس"),
        choices=[("", _("الكل"))] + list(SurvivorProfile.Gender.choices),
        widget=forms.Select(attrs={"class": "form-select"}),
    )
