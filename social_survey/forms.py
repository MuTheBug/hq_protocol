from django import forms

from .models import (
    Child, EducationStatus, EmploymentInfo, HealthAccess,
    HousingInfo, HouseholdSurvey, NeedsAssessment,
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


class HouseholdSurveyForm(forms.ModelForm):
    class Meta:
        model = HouseholdSurvey
        exclude = ("survivor", "surveyor", "created_at", "updated_at")
        widgets = {
            "survey_date": forms.DateInput(attrs={"type": "date"}),
            "survey_notes": forms.Textarea(attrs={"rows": 3}),
        }

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        _bootstrapify(self)


class ChildForm(forms.ModelForm):
    class Meta:
        model = Child
        exclude = ("household",)
        widgets = {
            "birth_date": forms.DateInput(attrs={"type": "date"}),
            "dropout_reason": forms.Textarea(attrs={"rows": 2}),
            "disability_description": forms.Textarea(attrs={"rows": 2}),
            "chronic_illness_description": forms.Textarea(attrs={"rows": 2}),
            "psychological_notes": forms.Textarea(attrs={"rows": 2}),
            "notes": forms.Textarea(attrs={"rows": 2}),
        }

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        _bootstrapify(self)


class HousingInfoForm(forms.ModelForm):
    class Meta:
        model = HousingInfo
        exclude = ("household",)
        widgets = {
            "address": forms.Textarea(attrs={"rows": 2}),
            "original_home_status": forms.Textarea(attrs={"rows": 2}),
            "confiscation_details": forms.Textarea(attrs={"rows": 2}),
            "notes": forms.Textarea(attrs={"rows": 2}),
        }

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        _bootstrapify(self)


class EducationStatusForm(forms.ModelForm):
    class Meta:
        model = EducationStatus
        exclude = ("survivor",)
        widgets = {
            "obstacles_to_education": forms.Textarea(attrs={"rows": 2}),
            "certificates_details": forms.Textarea(attrs={"rows": 2}),
        }

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        _bootstrapify(self)


class EmploymentInfoForm(forms.ModelForm):
    class Meta:
        model = EmploymentInfo
        exclude = ("survivor",)
        widgets = {
            "other_income_sources": forms.Textarea(attrs={"rows": 2}),
            "notes": forms.Textarea(attrs={"rows": 2}),
        }

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        _bootstrapify(self)


class HealthAccessForm(forms.ModelForm):
    class Meta:
        model = HealthAccess
        exclude = ("household",)
        widgets = {
            "chronic_illnesses_in_family": forms.Textarea(attrs={"rows": 2}),
            "unmet_medical_needs": forms.Textarea(attrs={"rows": 2}),
            "notes": forms.Textarea(attrs={"rows": 2}),
        }

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        _bootstrapify(self)


class NeedsAssessmentForm(forms.ModelForm):
    class Meta:
        model = NeedsAssessment
        exclude = ("household", "assessed_by")
        widgets = {
            "assessment_date": forms.DateInput(attrs={"type": "date"}),
            "follow_up_date": forms.DateInput(attrs={"type": "date"}),
            "additional_needs": forms.Textarea(attrs={"rows": 3}),
            "barriers_to_aid": forms.Textarea(attrs={"rows": 2}),
            "notes": forms.Textarea(attrs={"rows": 2}),
        }

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        _bootstrapify(self)
