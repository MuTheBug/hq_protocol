from django.contrib import admin

from .models import AuthToken, SyncBatch


@admin.register(AuthToken)
class AuthTokenAdmin(admin.ModelAdmin):
    list_display = ("user", "device_name", "device_id", "created_at", "last_used_at", "revoked")
    list_filter = ("revoked", "created_at")
    search_fields = ("user__username", "device_name", "device_id")
    readonly_fields = ("key", "created_at", "last_used_at")


@admin.register(SyncBatch)
class SyncBatchAdmin(admin.ModelAdmin):
    list_display = ("created_at", "user", "device_id", "direction", "records_count",
                    "success_count", "error_count")
    list_filter = ("direction", "created_at")
    search_fields = ("user__username", "device_id")
    readonly_fields = ("created_at",)
