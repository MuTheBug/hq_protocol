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
    """قوائم متدرّجة: محافظة → مدينة → حي. يتم التحقق دون قيد على choices لأن
    المدن والأحياء تتولّد عبر JavaScript من ملف syria_geo."""

    from survivors.choices import SyrianGovernorate
    from survivors.syria_geo import SYRIA_CITIES

    governorate = forms.ChoiceField(
        label="المحافظة", required=False,
        choices=[("", "—")] + SyrianGovernorate.CHOICES,
    )

    class Meta:
        model = HousingInfo
        exclude = ("household",)
        widgets = {
            "address": forms.Textarea(attrs={"rows": 2}),
            "original_home_status": forms.Textarea(attrs={"rows": 2}),
            "confiscation_details": forms.Textarea(attrs={"rows": 2}),
            "notes": forms.Textarea(attrs={"rows": 2}),
            "city": forms.Select(),
            "neighborhood": forms.Select(),
        }

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        # city و neighborhood يتم ملؤهما عبر JS، لذلك نسمح بأي قيمة
        from survivors.syria_geo import SYRIA_CITIES
        gov = self.data.get("governorate") if self.is_bound else (
            self.initial.get("governorate") or (self.instance and self.instance.governorate)
        )
        city = self.data.get("city") if self.is_bound else (
            self.initial.get("city") or (self.instance and self.instance.city)
        )

        # قوائم ابتدائية بسيطة (JS سيُحدّثها)
        city_choices = [("", "—")]
        if gov and gov in SYRIA_CITIES:
            for city_name, _ngh in SYRIA_CITIES[gov]:
                city_choices.append((city_name, city_name))
        elif city:
            city_choices.append((city, city))
        self.fields["city"] = forms.ChoiceField(
            label="المدينة/البلدة", required=False, choices=city_choices,
        )

        neighborhood_choices = [("", "—")]
        if gov and city:
            for city_name, neighborhoods in SYRIA_CITIES.get(gov, []):
                if city_name == city:
                    for n in neighborhoods:
                        neighborhood_choices.append((n, n))
                    break
        elif self.instance and self.instance.neighborhood:
            neighborhood_choices.append(
                (self.instance.neighborhood, self.instance.neighborhood),
            )
        self.fields["neighborhood"] = forms.ChoiceField(
            label="الحي", required=False, choices=neighborhood_choices,
        )

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
