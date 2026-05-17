from django import forms
from django.contrib.auth.forms import UserCreationForm, AuthenticationForm
from django.utils.translation import gettext_lazy as _

from .models import User


class LoginForm(AuthenticationForm):
    username = forms.CharField(
        label=_("اسم المستخدم"),
        widget=forms.TextInput(attrs={"class": "form-control", "autofocus": True}),
    )
    password = forms.CharField(
        label=_("كلمة المرور"),
        widget=forms.PasswordInput(attrs={"class": "form-control"}),
    )


class UserRegistrationForm(UserCreationForm):
    class Meta:
        model = User
        fields = (
            "username", "full_name_ar", "email", "organization",
            "phone", "role", "password1", "password2",
        )
        widgets = {
            "username": forms.TextInput(attrs={"class": "form-control"}),
            "full_name_ar": forms.TextInput(attrs={"class": "form-control"}),
            "email": forms.EmailInput(attrs={"class": "form-control"}),
            "organization": forms.TextInput(attrs={"class": "form-control"}),
            "phone": forms.TextInput(attrs={"class": "form-control"}),
            "role": forms.Select(attrs={"class": "form-select"}),
        }

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        for name in ("password1", "password2"):
            self.fields[name].widget.attrs["class"] = "form-control"


class UserProfileForm(forms.ModelForm):
    class Meta:
        model = User
        fields = (
            "full_name_ar", "email", "organization", "phone",
            "confidentiality_agreement_signed", "confidentiality_signed_date",
            "training_istanbul_protocol", "training_berkeley_protocol",
            "training_completion_date",
        )
        widgets = {
            "full_name_ar": forms.TextInput(attrs={"class": "form-control"}),
            "email": forms.EmailInput(attrs={"class": "form-control"}),
            "organization": forms.TextInput(attrs={"class": "form-control"}),
            "phone": forms.TextInput(attrs={"class": "form-control"}),
            "confidentiality_signed_date": forms.DateInput(
                attrs={"class": "form-control", "type": "date"}
            ),
            "training_completion_date": forms.DateInput(
                attrs={"class": "form-control", "type": "date"}
            ),
        }
