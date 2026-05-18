from django.conf import settings
from django.db import models
from django.utils.translation import gettext_lazy as _


class TutorialProgress(models.Model):
    """تقدّم المستخدم في كل درس - يُسجَّل عند بدء/إكمال الدرس."""

    user = models.ForeignKey(
        settings.AUTH_USER_MODEL, on_delete=models.CASCADE,
        related_name="tutorial_progress",
    )
    lesson_id = models.CharField(_("معرّف الدرس"), max_length=50, db_index=True)
    started_at = models.DateTimeField(auto_now_add=True)
    completed_at = models.DateTimeField(_("تاريخ الإكمال"), null=True, blank=True)
    quiz_score = models.PositiveSmallIntegerField(
        _("درجة الاختبار"), null=True, blank=True,
    )
    quiz_max = models.PositiveSmallIntegerField(
        _("الحد الأقصى للاختبار"), null=True, blank=True,
    )
    last_visited_at = models.DateTimeField(auto_now=True)

    class Meta:
        verbose_name = _("تقدّم درس")
        verbose_name_plural = _("تقدّم الدروس")
        unique_together = [("user", "lesson_id")]
        ordering = ["user", "lesson_id"]

    def __str__(self):
        return f"{self.user} → {self.lesson_id}"

    @property
    def is_completed(self):
        return self.completed_at is not None

    @property
    def quiz_percent(self):
        if not self.quiz_score or not self.quiz_max:
            return None
        return round(self.quiz_score / self.quiz_max * 100)
