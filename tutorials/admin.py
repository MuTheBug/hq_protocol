from django.contrib import admin

from .models import TutorialProgress


@admin.register(TutorialProgress)
class TutorialProgressAdmin(admin.ModelAdmin):
    list_display = (
        "user", "lesson_id", "completed_at", "quiz_score", "quiz_max",
        "last_visited_at",
    )
    list_filter = ("lesson_id", "completed_at")
    search_fields = ("user__username", "user__full_name_ar", "lesson_id")
    readonly_fields = ("started_at", "last_visited_at")
