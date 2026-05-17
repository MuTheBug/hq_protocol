from django.contrib import messages
from django.contrib.auth.decorators import login_required
from django.http import HttpResponseForbidden
from django.shortcuts import get_object_or_404, redirect, render
from django.utils.translation import gettext_lazy as _

from accounts.models import AuditLog
from survivors.models import SurvivorProfile

from .forms import (
    ChildForm, EducationStatusForm, EmploymentInfoForm, HealthAccessForm,
    HousingInfoForm, HouseholdSurveyForm, NeedsAssessmentForm,
)
from .models import (
    Child, EducationStatus, EmploymentInfo, HealthAccess,
    HousingInfo, HouseholdSurvey, NeedsAssessment,
)


def _can_document(user):
    return user.is_authenticated and (user.is_superuser or user.can_document)


def _log(request, action, obj):
    AuditLog.objects.create(
        user=request.user, action=action,
        target_model=obj.__class__.__name__,
        target_id=str(obj.pk), target_repr=str(obj)[:255],
        path=request.path, ip_address=request.META.get("REMOTE_ADDR"),
    )


@login_required
def survey_list(request):
    surveys = (
        HouseholdSurvey.objects
        .select_related("survivor", "surveyor")
        .order_by("-survey_date")
    )
    return render(request, "social_survey/list.html", {
        "surveys": surveys, "total": surveys.count(),
    })


@login_required
def household_create_or_edit(request, survivor_pk):
    if not _can_document(request.user):
        return HttpResponseForbidden(_("لا تملك صلاحية إدخال مسح اجتماعي."))
    survivor = get_object_or_404(SurvivorProfile, pk=survivor_pk)
    instance = getattr(survivor, "household_survey", None)
    if request.method == "POST":
        form = HouseholdSurveyForm(request.POST, instance=instance)
        if form.is_valid():
            household = form.save(commit=False)
            household.survivor = survivor
            if not household.surveyor_id:
                household.surveyor = request.user
            household.save()
            _log(request, AuditLog.Action.UPDATE if instance else AuditLog.Action.CREATE, household)
            messages.success(request, _("تم حفظ المسح الاجتماعي."))
            return redirect("social_survey:household_detail", pk=household.pk)
    else:
        form = HouseholdSurveyForm(instance=instance)
    return render(request, "social_survey/household_form.html", {
        "form": form, "survivor": survivor,
        "title": _("المسح الاجتماعي للأسرة"),
    })


@login_required
def household_detail(request, pk):
    household = get_object_or_404(HouseholdSurvey, pk=pk)
    _log(request, AuditLog.Action.VIEW, household)
    return render(request, "social_survey/household_detail.html", {
        "household": household,
        "survivor": household.survivor,
        "children": household.children.all(),
        "housing": getattr(household, "housing", None),
        "health": getattr(household, "health_access", None),
        "needs": getattr(household, "needs", None),
        "education": getattr(household.survivor, "education", None),
        "employment": getattr(household.survivor, "employment", None),
    })


@login_required
def child_add(request, household_pk):
    if not _can_document(request.user):
        return HttpResponseForbidden()
    household = get_object_or_404(HouseholdSurvey, pk=household_pk)
    if request.method == "POST":
        form = ChildForm(request.POST)
        if form.is_valid():
            child = form.save(commit=False)
            child.household = household
            child.save()
            _log(request, AuditLog.Action.CREATE, child)
            messages.success(request, _("تم إضافة بيانات الابن/الابنة."))
            return redirect("social_survey:household_detail", pk=household.pk)
    else:
        form = ChildForm()
    return render(request, "social_survey/sub_form.html", {
        "form": form, "household": household,
        "title": _("إضافة ابن/ابنة"), "submit_label": _("حفظ"),
    })


@login_required
def child_edit(request, pk):
    if not _can_document(request.user):
        return HttpResponseForbidden()
    child = get_object_or_404(Child, pk=pk)
    if request.method == "POST":
        form = ChildForm(request.POST, instance=child)
        if form.is_valid():
            form.save()
            _log(request, AuditLog.Action.UPDATE, child)
            messages.success(request, _("تم حفظ التعديلات."))
            return redirect("social_survey:household_detail", pk=child.household.pk)
    else:
        form = ChildForm(instance=child)
    return render(request, "social_survey/sub_form.html", {
        "form": form, "household": child.household,
        "title": _("تعديل بيانات ابن/ابنة"), "submit_label": _("حفظ"),
    })


@login_required
def housing_edit(request, household_pk):
    if not _can_document(request.user):
        return HttpResponseForbidden()
    household = get_object_or_404(HouseholdSurvey, pk=household_pk)
    instance = getattr(household, "housing", None)
    if request.method == "POST":
        form = HousingInfoForm(request.POST, instance=instance)
        if form.is_valid():
            housing = form.save(commit=False)
            housing.household = household
            housing.save()
            _log(request, AuditLog.Action.UPDATE if instance else AuditLog.Action.CREATE, housing)
            messages.success(request, _("تم حفظ بيانات السكن."))
            return redirect("social_survey:household_detail", pk=household.pk)
    else:
        form = HousingInfoForm(instance=instance)
    return render(request, "social_survey/sub_form.html", {
        "form": form, "household": household,
        "title": _("بيانات السكن"), "submit_label": _("حفظ"),
    })


@login_required
def health_edit(request, household_pk):
    if not _can_document(request.user):
        return HttpResponseForbidden()
    household = get_object_or_404(HouseholdSurvey, pk=household_pk)
    instance = getattr(household, "health_access", None)
    if request.method == "POST":
        form = HealthAccessForm(request.POST, instance=instance)
        if form.is_valid():
            health = form.save(commit=False)
            health.household = household
            health.save()
            _log(request, AuditLog.Action.UPDATE if instance else AuditLog.Action.CREATE, health)
            messages.success(request, _("تم حفظ بيانات الصحة."))
            return redirect("social_survey:household_detail", pk=household.pk)
    else:
        form = HealthAccessForm(instance=instance)
    return render(request, "social_survey/sub_form.html", {
        "form": form, "household": household,
        "title": _("الوصول للرعاية الصحية"), "submit_label": _("حفظ"),
    })


@login_required
def needs_edit(request, household_pk):
    if not _can_document(request.user):
        return HttpResponseForbidden()
    household = get_object_or_404(HouseholdSurvey, pk=household_pk)
    instance = getattr(household, "needs", None)
    if request.method == "POST":
        form = NeedsAssessmentForm(request.POST, instance=instance)
        if form.is_valid():
            needs = form.save(commit=False)
            needs.household = household
            if not needs.assessed_by_id:
                needs.assessed_by = request.user
            needs.save()
            _log(request, AuditLog.Action.UPDATE if instance else AuditLog.Action.CREATE, needs)
            messages.success(request, _("تم حفظ تقييم الاحتياجات."))
            return redirect("social_survey:household_detail", pk=household.pk)
    else:
        form = NeedsAssessmentForm(instance=instance)
    return render(request, "social_survey/sub_form.html", {
        "form": form, "household": household,
        "title": _("تقييم الاحتياجات"), "submit_label": _("حفظ"),
    })


@login_required
def education_edit(request, survivor_pk):
    if not _can_document(request.user):
        return HttpResponseForbidden()
    survivor = get_object_or_404(SurvivorProfile, pk=survivor_pk)
    instance = getattr(survivor, "education", None)
    if request.method == "POST":
        form = EducationStatusForm(request.POST, instance=instance)
        if form.is_valid():
            edu = form.save(commit=False)
            edu.survivor = survivor
            edu.save()
            _log(request, AuditLog.Action.UPDATE if instance else AuditLog.Action.CREATE, edu)
            messages.success(request, _("تم حفظ بيانات التعليم."))
            household = getattr(survivor, "household_survey", None)
            if household:
                return redirect("social_survey:household_detail", pk=household.pk)
            return redirect("survivors:detail", pk=survivor.pk)
    else:
        form = EducationStatusForm(instance=instance)
    return render(request, "social_survey/sub_form.html", {
        "form": form, "survivor": survivor,
        "title": _("الوضع التعليمي للناجي"), "submit_label": _("حفظ"),
    })


@login_required
def employment_edit(request, survivor_pk):
    if not _can_document(request.user):
        return HttpResponseForbidden()
    survivor = get_object_or_404(SurvivorProfile, pk=survivor_pk)
    instance = getattr(survivor, "employment", None)
    if request.method == "POST":
        form = EmploymentInfoForm(request.POST, instance=instance)
        if form.is_valid():
            emp = form.save(commit=False)
            emp.survivor = survivor
            emp.save()
            _log(request, AuditLog.Action.UPDATE if instance else AuditLog.Action.CREATE, emp)
            messages.success(request, _("تم حفظ بيانات العمل والدخل."))
            household = getattr(survivor, "household_survey", None)
            if household:
                return redirect("social_survey:household_detail", pk=household.pk)
            return redirect("survivors:detail", pk=survivor.pk)
    else:
        form = EmploymentInfoForm(instance=instance)
    return render(request, "social_survey/sub_form.html", {
        "form": form, "survivor": survivor,
        "title": _("العمل والدخل"), "submit_label": _("حفظ"),
    })
