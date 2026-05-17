from django.contrib import admin
from django.utils.html import format_html
from django.utils.translation import gettext_lazy as _

from .models import (
    ChainOfCustodyLog, DetentionEvent, DetentionFacility, DetentionPeriod,
    InformedConsent, Interview, InterviewMedia, LongTermImpact,
    MedicalAssessment, ReleaseEvent, SupportingDocument, SurvivorNote,
    SurvivorProfile, TortureMethod, Witness,
)


@admin.register(DetentionFacility)
class DetentionFacilityAdmin(admin.ModelAdmin):
    list_display = ("name_ar", "branch_number", "parent_entity", "governorate")
    list_filter = ("parent_entity", "governorate")
    search_fields = ("name_ar", "name_en", "branch_number", "address")


@admin.register(TortureMethod)
class TortureMethodAdmin(admin.ModelAdmin):
    list_display = ("name_ar", "category", "name_en")
    list_filter = ("category",)
    search_fields = ("name_ar", "name_en", "description")


class DetentionEventInline(admin.TabularInline):
    model = DetentionEvent
    extra = 0
    fields = (
        "detention_date", "detention_location", "arresting_entity", "reason_stated",
    )


class DetentionPeriodInline(admin.TabularInline):
    model = DetentionPeriod
    extra = 0
    fields = (
        "order_index", "facility", "from_date", "to_date",
        "sexual_violence_reported",
    )
    autocomplete_fields = ["facility"]


class WitnessInline(admin.TabularInline):
    model = Witness
    extra = 0
    fields = (
        "witness_name", "facility_witnessed_at", "period_from",
        "is_independent", "consent_to_use_testimony",
    )
    autocomplete_fields = ["facility_witnessed_at"]


class SupportingDocumentInline(admin.TabularInline):
    model = SupportingDocument
    extra = 0
    fields = ("document_type", "title", "date_obtained", "file_hash_sha256")
    readonly_fields = ("file_hash_sha256",)


class InformedConsentInline(admin.StackedInline):
    model = InformedConsent
    extra = 0
    max_num = 1
    fieldsets = (
        (_("الموافقة الأساسية"), {
            "fields": (
                "consent_documented", "consent_date", "consent_witness",
                "consent_form_file",
            )
        }),
        (_("مَن يُسمح بالمشاركة معه"), {
            "fields": (
                "share_with_iiim", "share_with_coi", "share_with_icc",
                "share_with_universal_jurisdiction", "share_with_partner_orgs",
                "share_with_media", "share_publicly",
            )
        }),
        (_("إخفاء الهوية"), {
            "fields": (
                "anonymize_name", "anonymize_photo",
                "anonymize_location", "anonymize_family_details",
            )
        }),
        (_("الفهم والموافقة المستنيرة"), {
            "fields": (
                "withdrawal_right_explained",
                "confidentiality_limits_explained",
                "intended_uses_explained",
            )
        }),
        (_("سحب الموافقة"), {
            "classes": ("collapse",),
            "fields": (
                "consent_withdrawn", "withdrawal_date", "withdrawal_reason",
            )
        }),
        (_("ملاحظات"), {"fields": ("notes",)}),
    )


class ReleaseEventInline(admin.StackedInline):
    model = ReleaseEvent
    extra = 0
    max_num = 1


class LongTermImpactInline(admin.StackedInline):
    model = LongTermImpact
    extra = 0
    max_num = 1


class MedicalAssessmentInline(admin.TabularInline):
    model = MedicalAssessment
    extra = 0
    fields = (
        "assessment_type", "assessment_date", "assessor_name",
        "istanbul_protocol_compliant",
    )


@admin.register(SurvivorProfile)
class SurvivorProfileAdmin(admin.ModelAdmin):
    list_display = (
        "case_reference", "full_name", "gender",
        "governorate_at_detention",
        "file_classification_badge", "overall_score", "documenter", "created_at",
    )
    list_filter = (
        "file_classification", "gender",
        "governorate_at_detention", "current_country",
        "occupation_category", "political_activity_category",
        "marital_status_at_detention",
    )
    search_fields = (
        "case_reference", "first_name", "father_name", "family_name",
        "national_id", "alias",
    )
    date_hierarchy = "created_at"
    readonly_fields = (
        "case_uid", "created_at", "updated_at", "overall_score",
        "reliability_score", "corroboration_score", "completeness_score",
    )
    autocomplete_fields = ["documenter"]

    fieldsets = (
        (_("المعرّفات"), {
            "fields": ("case_reference", "case_uid", "file_classification"),
        }),
        (_("الاسم"), {
            "fields": (
                "first_name", "father_name", "grandfather_name",
                "family_name", "mother_name", "alias",
            ),
        }),
        (_("بيانات الهوية"), {
            "fields": (
                "national_id", "birth_date", "birth_date_approximate",
                "birth_governorate", "birth_place_detail",
                "gender", "nationality",
                "marital_status_at_detention",
            ),
        }),
        (_("وقت الاعتقال"), {
            "fields": (
                "address_at_detention", "governorate_at_detention",
                "occupation_category", "occupation_detail",
                "political_activity_category", "political_activity_detail",
            ),
        }),
        (_("معلومات اتصال حالية"), {
            "fields": (
                "current_phone", "current_email",
                "current_country", "current_governorate", "current_city",
                "next_of_kin_name", "next_of_kin_relation",
                "next_of_kin_phone",
            ),
        }),
        (_("الصور"), {
            "fields": ("photo_recent", "photo_before_detention"),
            "classes": ("collapse",),
        }),
        (_("التوثيق"), {
            "fields": ("documenter",),
        }),
        (_("التقييم الآلي (محسوب من البيانات)"), {
            "fields": (
                "reliability_score", "corroboration_score",
                "completeness_score", "overall_score",
            ),
        }),
        (_("الإحالات"), {
            "fields": (
                "medical_referral_offered", "psychological_referral_offered",
                "legal_aid_offered", "referral_notes",
            ),
            "classes": ("collapse",),
        }),
        (_("تواريخ"), {
            "fields": ("created_at", "updated_at"),
            "classes": ("collapse",),
        }),
    )

    inlines = [
        InformedConsentInline,
        DetentionEventInline,
        DetentionPeriodInline,
        ReleaseEventInline,
        WitnessInline,
        SupportingDocumentInline,
        MedicalAssessmentInline,
        LongTermImpactInline,
    ]

    @admin.display(description=_("التصنيف"), ordering="file_classification")
    def file_classification_badge(self, obj):
        colors = {
            "A": "#198754",
            "B": "#0d6efd",
            "C": "#6c757d",
            "draft": "#fd7e14",
        }
        color = colors.get(obj.file_classification, "#6c757d")
        return format_html(
            '<span style="background:{};color:#fff;padding:2px 8px;'
            'border-radius:4px;font-size:11px;">{}</span>',
            color, obj.get_file_classification_display(),
        )

    def save_model(self, request, obj, form, change):
        if not obj.documenter:
            obj.documenter = request.user
        super().save_model(request, obj, form, change)


@admin.register(DetentionEvent)
class DetentionEventAdmin(admin.ModelAdmin):
    list_display = (
        "survivor", "detention_date", "detention_location", "arresting_entity",
    )
    list_filter = ("detention_date", "governorate")
    search_fields = (
        "survivor__case_reference", "survivor__first_name",
        "survivor__family_name", "arresting_entity",
    )
    autocomplete_fields = ["survivor"]


@admin.register(DetentionPeriod)
class DetentionPeriodAdmin(admin.ModelAdmin):
    list_display = (
        "survivor", "facility", "from_date", "to_date", "duration_days",
        "sexual_violence_reported",
    )
    list_filter = ("facility__parent_entity", "facility", "sexual_violence_reported")
    search_fields = (
        "survivor__case_reference", "survivor__first_name",
        "survivor__family_name", "facility__name_ar",
    )
    filter_horizontal = ("torture_methods",)
    autocomplete_fields = ["survivor", "facility"]


@admin.register(Witness)
class WitnessAdmin(admin.ModelAdmin):
    list_display = (
        "witness_name", "survivor", "facility_witnessed_at",
        "is_independent", "consent_to_use_testimony",
    )
    list_filter = ("is_independent", "consent_to_use_testimony", "declaration_signed")
    search_fields = (
        "witness_name", "survivor__case_reference",
        "survivor__first_name", "survivor__family_name",
    )
    autocomplete_fields = ["survivor", "facility_witnessed_at"]


class ChainOfCustodyLogInline(admin.TabularInline):
    model = ChainOfCustodyLog
    extra = 1
    readonly_fields = ("timestamp",)


@admin.register(SupportingDocument)
class SupportingDocumentAdmin(admin.ModelAdmin):
    list_display = (
        "title", "survivor", "document_type", "date_obtained",
        "obtained_by", "has_hash",
    )
    list_filter = ("document_type", "date_obtained", "metadata_verified")
    search_fields = (
        "title", "description", "source_description",
        "survivor__case_reference", "document_reference_number",
    )
    readonly_fields = ("file_hash_sha256", "file_size_bytes", "created_at")
    autocomplete_fields = ["survivor", "obtained_by"]
    inlines = [ChainOfCustodyLogInline]

    @admin.display(description=_("بصمة SHA-256"), boolean=True)
    def has_hash(self, obj):
        return bool(obj.file_hash_sha256)


@admin.register(MedicalAssessment)
class MedicalAssessmentAdmin(admin.ModelAdmin):
    list_display = (
        "survivor", "assessment_type", "assessment_date",
        "assessor_name", "istanbul_protocol_compliant",
    )
    list_filter = (
        "assessment_type", "istanbul_protocol_compliant",
        "ptsd_indicators", "depression_indicators",
    )
    search_fields = (
        "survivor__case_reference", "assessor_name", "assessor_organization",
    )
    autocomplete_fields = ["survivor"]


@admin.register(InformedConsent)
class InformedConsentAdmin(admin.ModelAdmin):
    list_display = (
        "survivor", "consent_documented", "consent_date",
        "share_with_iiim", "share_with_icc", "consent_withdrawn",
    )
    list_filter = (
        "consent_documented", "consent_withdrawn",
        "share_with_iiim", "share_with_coi", "share_with_icc",
    )
    search_fields = ("survivor__case_reference",)
    autocomplete_fields = ["survivor"]


@admin.register(SurvivorNote)
class SurvivorNoteAdmin(admin.ModelAdmin):
    list_display = (
        "survivor", "note_type", "title", "is_pinned",
        "is_confidential", "author", "created_at",
    )
    list_filter = ("note_type", "is_pinned", "is_confidential")
    search_fields = (
        "survivor__case_reference", "survivor__first_name",
        "survivor__family_name", "title", "content",
    )
    autocomplete_fields = ["survivor", "author"]
    date_hierarchy = "created_at"


class InterviewMediaInline(admin.TabularInline):
    model = InterviewMedia
    extra = 0
    fields = ("media_type", "title", "file", "part_number", "duration_seconds")
    readonly_fields = ("file_hash_sha256",)


@admin.register(Interview)
class InterviewAdmin(admin.ModelAdmin):
    list_display = (
        "survivor", "sequence_number", "interview_date",
        "location_type", "interviewer", "recorded", "media_count",
    )
    list_filter = (
        "is_first", "recorded", "location_type", "methodology",
        "language", "gender_appropriate",
    )
    search_fields = (
        "survivor__case_reference", "survivor__first_name",
        "survivor__family_name", "summary",
    )
    autocomplete_fields = ["survivor", "interviewer", "note_taker"]
    date_hierarchy = "interview_date"
    inlines = [InterviewMediaInline]


@admin.register(InterviewMedia)
class InterviewMediaAdmin(admin.ModelAdmin):
    list_display = (
        "title", "media_type", "interview", "part_number",
        "duration_seconds", "uploaded_by",
    )
    list_filter = ("media_type",)
    search_fields = (
        "title", "description",
        "interview__survivor__case_reference",
    )
    readonly_fields = ("file_hash_sha256", "file_size_bytes")
    autocomplete_fields = ["interview", "uploaded_by"]
