from django.contrib import admin
from django.contrib.auth.admin import UserAdmin

from .models import AuditLog, User


@admin.register(User)
class CustomUserAdmin(UserAdmin):
    list_display = (
        "username", "full_name_ar", "role", "organization",
        "confidentiality_agreement_signed", "is_active",
    )
    list_filter = ("role", "is_active", "confidentiality_agreement_signed", "is_staff")
    search_fields = ("username", "full_name_ar", "email", "organization")
    fieldsets = UserAdmin.fieldsets + (
        ("معلومات حقّنا", {
            "fields": (
                "full_name_ar", "role", "organization", "phone", "notes",
            ),
        }),
        ("اتفاقية السرّية والتدريب", {
            "fields": (
                "confidentiality_agreement_signed", "confidentiality_signed_date",
                "training_istanbul_protocol", "training_berkeley_protocol",
                "training_completion_date",
            ),
        }),
    )


@admin.register(AuditLog)
class AuditLogAdmin(admin.ModelAdmin):
    list_display = (
        "timestamp", "user", "action", "target_model", "target_repr", "ip_address",
    )
    list_filter = ("action", "target_model", "timestamp")
    search_fields = (
        "user__username", "user__full_name_ar", "target_repr", "ip_address", "path",
    )
    readonly_fields = (
        "user", "action", "target_model", "target_id", "target_repr",
        "ip_address", "user_agent", "path", "notes", "timestamp",
    )
    date_hierarchy = "timestamp"

    def has_add_permission(self, request):
        return False

    def has_change_permission(self, request, obj=None):
        return False

    def has_delete_permission(self, request, obj=None):
        return request.user.is_superuser
