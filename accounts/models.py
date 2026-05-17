from django.contrib.auth.models import AbstractUser
from django.db import models
from django.utils.translation import gettext_lazy as _


class User(AbstractUser):
    """مستخدم النظام: موثّق، مشرف، مدير، مدقق، أو ضابط حماية."""

    class Role(models.TextChoices):
        DOCUMENTER = "documenter", _("موثّق ميداني")
        SUPERVISOR = "supervisor", _("مشرف توثيق")
        REVIEWER = "reviewer", _("مدقّق/مراجع")
        PROTECTION = "protection", _("ضابط حماية وأمن البيانات")
        ADMIN = "admin", _("مدير النظام")
        READ_ONLY = "read_only", _("اطلاع فقط")

    role = models.CharField(
        _("الدور"), max_length=20, choices=Role.choices, default=Role.DOCUMENTER
    )
    full_name_ar = models.CharField(_("الاسم الكامل (عربي)"), max_length=200, blank=True)
    organization = models.CharField(_("المنظمة/الجمعية"), max_length=200, blank=True)
    phone = models.CharField(_("رقم الهاتف"), max_length=30, blank=True)
    confidentiality_agreement_signed = models.BooleanField(
        _("اتفاقية السرّية موقّعة"), default=False
    )
    confidentiality_signed_date = models.DateField(
        _("تاريخ توقيع اتفاقية السرّية"), null=True, blank=True
    )
    training_istanbul_protocol = models.BooleanField(
        _("مدرَّب على بروتوكول إسطنبول"), default=False
    )
    training_berkeley_protocol = models.BooleanField(
        _("مدرَّب على بروتوكول بيركلي"), default=False
    )
    training_completion_date = models.DateField(
        _("تاريخ إتمام التدريب"), null=True, blank=True
    )
    notes = models.TextField(_("ملاحظات"), blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        verbose_name = _("مستخدم")
        verbose_name_plural = _("المستخدمون")

    def __str__(self):
        return self.full_name_ar or self.get_full_name() or self.username

    @property
    def can_document(self):
        return self.role in {
            self.Role.DOCUMENTER,
            self.Role.SUPERVISOR,
            self.Role.ADMIN,
        }

    @property
    def can_review(self):
        return self.role in {
            self.Role.SUPERVISOR,
            self.Role.REVIEWER,
            self.Role.ADMIN,
        }

    @property
    def can_view_sensitive(self):
        return self.role in {
            self.Role.SUPERVISOR,
            self.Role.REVIEWER,
            self.Role.PROTECTION,
            self.Role.ADMIN,
        }


class AuditLog(models.Model):
    """سجل تدقيق لكل عملية حساسة (مشاهدة/تعديل/حذف ملف ناجٍ أو وثيقة)."""

    class Action(models.TextChoices):
        VIEW = "view", _("اطلاع")
        CREATE = "create", _("إنشاء")
        UPDATE = "update", _("تعديل")
        DELETE = "delete", _("حذف")
        EXPORT = "export", _("تصدير")
        DOWNLOAD = "download", _("تنزيل")
        LOGIN = "login", _("تسجيل دخول")
        LOGOUT = "logout", _("تسجيل خروج")
        FAILED_LOGIN = "failed_login", _("محاولة دخول فاشلة")

    user = models.ForeignKey(
        User, on_delete=models.SET_NULL, null=True, blank=True,
        related_name="audit_entries", verbose_name=_("المستخدم"),
    )
    action = models.CharField(_("الإجراء"), max_length=20, choices=Action.choices)
    target_model = models.CharField(_("نوع السجل"), max_length=80, blank=True)
    target_id = models.CharField(_("معرّف السجل"), max_length=80, blank=True)
    target_repr = models.CharField(_("وصف السجل"), max_length=255, blank=True)
    ip_address = models.GenericIPAddressField(_("عنوان IP"), null=True, blank=True)
    user_agent = models.CharField(_("متصفح المستخدم"), max_length=500, blank=True)
    path = models.CharField(_("المسار"), max_length=500, blank=True)
    notes = models.TextField(_("ملاحظات"), blank=True)
    timestamp = models.DateTimeField(_("الوقت"), auto_now_add=True, db_index=True)

    class Meta:
        verbose_name = _("سجل تدقيق")
        verbose_name_plural = _("سجلات التدقيق")
        ordering = ["-timestamp"]

    def __str__(self):
        return f"{self.user or 'مجهول'} - {self.get_action_display()} - {self.timestamp:%Y-%m-%d %H:%M}"
