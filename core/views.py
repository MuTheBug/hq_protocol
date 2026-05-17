from django.contrib.auth.decorators import login_required
from django.db.models import Count, Q
from django.shortcuts import render

from accounts.models import AuditLog, User
from social_survey.models import Child, HouseholdSurvey
from survivors.models import (
    DetentionFacility, DetentionPeriod, SupportingDocument,
    SurvivorProfile, Witness,
)


@login_required
def dashboard(request):
    user = request.user

    survivor_qs = SurvivorProfile.objects.all()

    stats = {
        "total_survivors": survivor_qs.count(),
        "draft_files": survivor_qs.filter(file_classification="draft").count(),
        "class_a_files": survivor_qs.filter(file_classification="A").count(),
        "class_b_files": survivor_qs.filter(file_classification="B").count(),
        "class_c_files": survivor_qs.filter(file_classification="C").count(),
        "female_survivors": survivor_qs.filter(gender="female").count(),
        "male_survivors": survivor_qs.filter(gender="male").count(),
        "total_witnesses": Witness.objects.count(),
        "total_documents": SupportingDocument.objects.count(),
        "total_facilities": DetentionFacility.objects.count(),
        "total_households": HouseholdSurvey.objects.count(),
        "total_children": Child.objects.count(),
        "children_out_of_school": Child.objects.filter(
            Q(dropped_out=True) | Q(is_in_school=False)
        ).count(),
    }

    consent_compliant = survivor_qs.filter(
        consent__consent_documented=True,
        consent__withdrawal_right_explained=True,
        consent__confidentiality_limits_explained=True,
        consent__intended_uses_explained=True,
        consent__consent_withdrawn=False,
    ).count()
    stats["consent_compliant"] = consent_compliant
    stats["consent_pending"] = survivor_qs.count() - consent_compliant

    by_governorate = list(
        survivor_qs.exclude(governorate_at_detention="")
        .values("governorate_at_detention")
        .annotate(count=Count("id"))
        .order_by("-count")[:10]
    )

    by_facility = list(
        DetentionPeriod.objects.values(
            "facility__name_ar", "facility__branch_number"
        )
        .annotate(count=Count("id"))
        .order_by("-count")[:10]
    )

    recent_survivors = (
        survivor_qs.select_related("documenter").order_by("-created_at")[:10]
    )

    recent_audit = AuditLog.objects.select_related("user").order_by("-timestamp")[:15]

    return render(request, "core/dashboard.html", {
        "stats": stats,
        "by_governorate": by_governorate,
        "by_facility": by_facility,
        "recent_survivors": recent_survivors,
        "recent_audit": recent_audit,
    })


def home(request):
    if request.user.is_authenticated:
        return dashboard(request)
    from django.shortcuts import redirect
    return redirect("accounts:login")
