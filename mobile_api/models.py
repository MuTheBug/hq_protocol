"""Token authentication model للتطبيق المحمول."""

import secrets

from django.conf import settings
from django.db import models


class AuthToken(models.Model):
    """رمز مصادقة فريد لكل جهاز جوال يتصل بالـAPI."""

    key = models.CharField(max_length=64, primary_key=True)
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL, on_delete=models.CASCADE,
        related_name="mobile_tokens",
    )
    device_name = models.CharField(max_length=200, blank=True)
    device_id = models.CharField(max_length=200, blank=True, db_index=True)
    created_at = models.DateTimeField(auto_now_add=True)
    last_used_at = models.DateTimeField(auto_now=True)
    revoked = models.BooleanField(default=False)

    class Meta:
        verbose_name = "رمز جهاز جوال"
        verbose_name_plural = "رموز الأجهزة"
        ordering = ["-last_used_at"]

    def __str__(self):
        return f"{self.user.username} @ {self.device_name or 'unknown'}"

    @classmethod
    def generate(cls, user, device_name="", device_id=""):
        return cls.objects.create(
            key=secrets.token_urlsafe(48),
            user=user,
            device_name=device_name[:200],
            device_id=device_id[:200],
        )


class SyncBatch(models.Model):
    """سجل كل عملية مزامنة للتدقيق."""

    user = models.ForeignKey(
        settings.AUTH_USER_MODEL, on_delete=models.SET_NULL, null=True,
    )
    device_id = models.CharField(max_length=200, blank=True)
    direction = models.CharField(
        max_length=10, choices=[("push", "push"), ("pull", "pull")],
    )
    records_count = models.IntegerField(default=0)
    success_count = models.IntegerField(default=0)
    error_count = models.IntegerField(default=0)
    errors = models.JSONField(default=list, blank=True)
    created_at = models.DateTimeField(auto_now_add=True, db_index=True)

    class Meta:
        ordering = ["-created_at"]
