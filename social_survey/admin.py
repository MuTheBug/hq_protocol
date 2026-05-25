from django.contrib import admin
from django.utils.translation import gettext_lazy as _

from .models import (
    Child, EducationStatus, EmploymentInfo, HealthAccess,
    HousingInfo, HouseholdSurvey, NeedsAssessment,
)


class ChildInline(admin.TabularInline):
    model = Child
    extra = 0
    fields = (
        "name", "gender", "age", "current_stage",
        "is_in_school", "dropped_out", "work_status",
    )


class HousingInline(admin.StackedInline):
    model = HousingInfo
    extra = 0
    max_num = 1


class HealthInline(admin.StackedInline):
    model = HealthAccess
    extra = 0
    max_num = 1


class NeedsInline(admin.StackedInline):
    model = NeedsAssessment
    extra = 0
    max_num = 1


@admin.register(HouseholdSurvey)
class HouseholdSurveyAdmin(admin.ModelAdmin):
    list_display = (
        "survivor", "marital_status", "household_size",
        "children_count", "displacement_status", "survey_date",
    )
    list_filter = (
        "marital_status", "displacement_status",
        "marital_status_changed_due_to_detention",
    )
    search_fields = (
        "survivor__case_reference", "survivor__first_name",
        "survivor__family_name", "spouse_name",
    )
    date_hierarchy = "survey_date"
    autocomplete_fields = ["survivor", "surveyor"]
    inlines = [ChildInline, HousingInline, HealthInline, NeedsInline]

    fieldsets = (
        (_("الناجي والمسح"), {
            "fields": (
                "survivor", "surveyor", "survey_date",
                "survey_location", "consent_to_survey",
            ),
        }),
        (_("الحالة الزوجية والأسرة"), {
            "fields": (
                "marital_status", "marital_status_changed_due_to_detention",
                "spouse_name", "spouse_age", "spouse_alive",
                "spouse_detained_now", "spouse_detained_before",
                "spouse_employed", "spouse_occupation",
            ),
        }),
        (_("حجم الأسرة"), {
            "fields": (
                "household_size", "dependents_count", "children_count",
            ),
        }),
        (_("التهجير"), {
            "fields": (
                "displacement_status", "displacement_count",
                "original_governorate", "current_governorate",
            ),
        }),
        (_("ملاحظات"), {"fields": ("survey_notes",)}),
    )

    def save_model(self, request, obj, form, change):
        if not obj.surveyor:
            obj.surveyor = request.user
        super().save_model(request, obj, form, change)


@admin.register(Child)
class ChildAdmin(admin.ModelAdmin):
    list_display = (
        "name", "household", "gender", "age", "current_stage",
        "is_in_school", "dropped_out", "work_status",
    )
    list_filter = (
        "gender", "current_stage", "is_in_school", "dropped_out",
        "work_status", "has_disability",
        "dropout_due_to_father_detention",
    )
    search_fields = (
        "name", "household__survivor__case_reference",
        "household__survivor__family_name",
    )
    autocomplete_fields = ["household"]

    fieldsets = (
        (_("بيانات أساسية"), {
            "fields": ("household", "name", "gender", "birth_date", "age"),
        }),
        (_("التعليم"), {
            "fields": (
                "is_in_school", "current_stage", "current_grade", "school_name",
                "dropped_out", "dropout_grade", "dropout_year",
                "dropout_due_to_father_detention", "dropout_reason",
                "wants_to_resume_education",
            ),
        }),
        (_("الصحة"), {
            "fields": (
                "has_disability", "disability_description",
                "has_chronic_illness", "chronic_illness_description",
                "psychological_issues", "psychological_notes",
            ),
        }),
        (_("العمل"), {
            "fields": (
                "work_status", "work_description",
                "work_started_due_to_detention",
            ),
        }),
        (_("ملاحظات"), {"fields": ("notes",)}),
    )


@admin.register(HousingInfo)
class HousingInfoAdmin(admin.ModelAdmin):
    list_display = (
        "household", "housing_type", "rent_amount", "rent_currency",
        "rent_overdue", "condition",
    )
    list_filter = (
        "housing_type", "condition", "rent_overdue",
        "threatened_with_eviction", "property_confiscated",
    )
    search_fields = (
        "household__survivor__case_reference",
        "household__survivor__family_name", "address",
    )
    autocomplete_fields = ["household"]


@admin.register(EducationStatus)
class EducationStatusAdmin(admin.ModelAdmin):
    list_display = (
        "survivor", "highest_level_before_detention",
        "highest_level_now", "is_currently_studying",
        "studies_interrupted_by_detention",
    )
    list_filter = (
        "highest_level_now", "is_currently_studying",
        "studies_interrupted_by_detention", "certificates_lost",
    )
    search_fields = ("survivor__case_reference", "field_of_study", "institution")
    autocomplete_fields = ["survivor"]


@admin.register(EmploymentInfo)
class EmploymentInfoAdmin(admin.ModelAdmin):
    list_display = (
        "survivor", "status", "current_occupation",
        "monthly_income", "income_currency",
        "income_covers_basic_needs",
    )
    list_filter = (
        "status", "income_currency", "income_covers_basic_needs",
        "unable_due_to_health", "unable_due_to_legal", "same_as_before",
    )
    search_fields = (
        "survivor__case_reference", "current_occupation",
    )
    autocomplete_fields = ["survivor"]


@admin.register(HealthAccess)
class HealthAccessAdmin(admin.ModelAdmin):
    list_display = (
        "household", "has_health_insurance", "access_to_primary_care",
        "food_security", "medications_unaffordable",
    )
    list_filter = (
        "has_health_insurance", "access_to_primary_care",
        "access_to_specialized_care", "food_security",
        "medications_unaffordable", "psychological_support_received",
    )
    search_fields = ("household__survivor__case_reference",)
    autocomplete_fields = ["household"]


@admin.register(NeedsAssessment)
class NeedsAssessmentAdmin(admin.ModelAdmin):
    list_display = (
        "household", "financial_aid_priority", "food_aid_priority",
        "medical_aid_priority", "legal_aid_priority", "assessment_date",
    )
    list_filter = (
        "financial_aid_priority", "food_aid_priority",
        "housing_aid_priority", "medical_aid_priority",
        "psychological_support_priority", "legal_aid_priority",
        "follow_up_required",
    )
    search_fields = ("household__survivor__case_reference",)
    date_hierarchy = "assessment_date"
    autocomplete_fields = ["household", "assessed_by"]
