from django.contrib import messages
from django.contrib.auth.decorators import login_required
from django.core.paginator import Paginator
from django.db.models import Q
from django.http import HttpResponseForbidden
from django.shortcuts import get_object_or_404, redirect, render
from django.utils.translation import gettext_lazy as _

from accounts.models import AuditLog

from .forms import (
    DetentionEventForm, DetentionPeriodForm, InformedConsentForm,
    MedicalAssessmentForm, ReleaseEventForm, SupportingDocumentForm,
    SurvivorProfileForm, SurvivorSearchForm, WitnessForm,
)
from .models import (
    InformedConsent, SurvivorProfile,
)


def _check_can_document(user):
    return user.is_authenticated and (user.is_superuser or user.can_document)


def _log_action(request, action, obj):
    AuditLog.objects.create(
        user=request.user,
        action=action,
        target_model=obj.__class__.__name__,
        target_id=str(obj.pk),
        target_repr=str(obj)[:255],
        path=request.path,
        ip_address=request.META.get("REMOTE_ADDR"),
    )


@login_required
def survivor_list(request):
    form = SurvivorSearchForm(request.GET or None)
    qs = SurvivorProfile.objects.select_related("documenter").order_by("-created_at")

    if form.is_valid():
        q = form.cleaned_data.get("q")
        if q:
            qs = qs.filter(
                Q(case_reference__icontains=q)
                | Q(first_name__icontains=q)
                | Q(father_name__icontains=q)
                | Q(family_name__icontains=q)
                | Q(national_id__icontains=q)
                | Q(alias__icontains=q)
            )
        if form.cleaned_data.get("status"):
            qs = qs.filter(status=form.cleaned_data["status"])
        if form.cleaned_data.get("classification"):
            qs = qs.filter(file_classification=form.cleaned_data["classification"])
        if form.cleaned_data.get("gender"):
            qs = qs.filter(gender=form.cleaned_data["gender"])

    paginator = Paginator(qs, 25)
    page = paginator.get_page(request.GET.get("page"))

    return render(request, "survivors/list.html", {
        "form": form, "page": page, "total": qs.count(),
    })


@login_required
def survivor_detail(request, pk):
    survivor = get_object_or_404(SurvivorProfile, pk=pk)
    _log_action(request, AuditLog.Action.VIEW, survivor)
    return render(request, "survivors/detail.html", {
        "survivor": survivor,
        "consent": getattr(survivor, "consent", None),
        "release": getattr(survivor, "release_event", None),
        "impact": getattr(survivor, "long_term_impact", None),
        "detention_events": survivor.detention_events.all(),
        "detention_periods": survivor.detention_periods.select_related("facility").all(),
        "witnesses": survivor.witnesses.select_related("facility_witnessed_at").all(),
        "documents": survivor.documents.all(),
        "medical_assessments": survivor.medical_assessments.all(),
    })


@login_required
def survivor_create(request):
    if not _check_can_document(request.user):
        return HttpResponseForbidden(_("لا تملك صلاحية إنشاء ملف ناجٍ."))
    if request.method == "POST":
        form = SurvivorProfileForm(request.POST, request.FILES)
        if form.is_valid():
            survivor = form.save(commit=False)
            survivor.documenter = request.user
            survivor.save()
            _log_action(request, AuditLog.Action.CREATE, survivor)
            messages.success(
                request,
                _("تم إنشاء ملف الناجي %(ref)s. الخطوة التالية: تسجيل الموافقة المستنيرة.")
                % {"ref": survivor.case_reference},
            )
            return redirect("survivors:consent_edit", pk=survivor.pk)
    else:
        last = SurvivorProfile.objects.order_by("-id").first()
        next_num = (last.id if last else 0) + 1
        form = SurvivorProfileForm(initial={
            "case_reference": f"HQ-2026-{next_num:04d}",
        })
    return render(request, "survivors/form.html", {
        "form": form, "title": _("إنشاء ملف ناجٍ جديد"),
        "submit_label": _("حفظ ومتابعة"),
    })


@login_required
def survivor_edit(request, pk):
    if not _check_can_document(request.user):
        return HttpResponseForbidden(_("لا تملك صلاحية تعديل ملف ناجٍ."))
    survivor = get_object_or_404(SurvivorProfile, pk=pk)
    if request.method == "POST":
        form = SurvivorProfileForm(request.POST, request.FILES, instance=survivor)
        if form.is_valid():
            form.save()
            _log_action(request, AuditLog.Action.UPDATE, survivor)
            messages.success(request, _("تم حفظ التعديلات."))
            return redirect("survivors:detail", pk=survivor.pk)
    else:
        form = SurvivorProfileForm(instance=survivor)
    return render(request, "survivors/form.html", {
        "form": form, "survivor": survivor,
        "title": _("تعديل ملف الناجي"), "submit_label": _("حفظ"),
    })


@login_required
def consent_edit(request, pk):
    if not _check_can_document(request.user):
        return HttpResponseForbidden(_("لا تملك صلاحية تعديل الموافقة."))
    survivor = get_object_or_404(SurvivorProfile, pk=pk)
    instance, _created = InformedConsent.objects.get_or_create(survivor=survivor)
    if request.method == "POST":
        form = InformedConsentForm(request.POST, request.FILES, instance=instance)
        if form.is_valid():
            form.save()
            _log_action(request, AuditLog.Action.UPDATE, instance)
            messages.success(request, _("تم حفظ الموافقة المستنيرة."))
            return redirect("survivors:detail", pk=survivor.pk)
    else:
        form = InformedConsentForm(instance=instance)
    return render(request, "survivors/consent_form.html", {
        "form": form, "survivor": survivor,
    })


@login_required
def detention_event_add(request, pk):
    if not _check_can_document(request.user):
        return HttpResponseForbidden()
    survivor = get_object_or_404(SurvivorProfile, pk=pk)
    if request.method == "POST":
        form = DetentionEventForm(request.POST)
        if form.is_valid():
            event = form.save(commit=False)
            event.survivor = survivor
            event.save()
            _log_action(request, AuditLog.Action.CREATE, event)
            messages.success(request, _("تم إضافة واقعة الاعتقال."))
            return redirect("survivors:detail", pk=survivor.pk)
    else:
        form = DetentionEventForm()
    return render(request, "survivors/sub_form.html", {
        "form": form, "survivor": survivor,
        "title": _("إضافة واقعة اعتقال"), "submit_label": _("حفظ"),
    })


@login_required
def detention_period_add(request, pk):
    if not _check_can_document(request.user):
        return HttpResponseForbidden()
    survivor = get_object_or_404(SurvivorProfile, pk=pk)
    if request.method == "POST":
        form = DetentionPeriodForm(request.POST)
        if form.is_valid():
            period = form.save(commit=False)
            period.survivor = survivor
            period.save()
            form.save_m2m()
            _log_action(request, AuditLog.Action.CREATE, period)
            messages.success(request, _("تم إضافة فترة الاحتجاز."))
            return redirect("survivors:detail", pk=survivor.pk)
    else:
        form = DetentionPeriodForm()
    return render(request, "survivors/sub_form.html", {
        "form": form, "survivor": survivor,
        "title": _("إضافة فترة احتجاز في فرع"),
        "submit_label": _("حفظ"),
    })


@login_required
def release_edit(request, pk):
    if not _check_can_document(request.user):
        return HttpResponseForbidden()
    survivor = get_object_or_404(SurvivorProfile, pk=pk)
    instance = getattr(survivor, "release_event", None)
    if request.method == "POST":
        form = ReleaseEventForm(request.POST, instance=instance)
        if form.is_valid():
            release = form.save(commit=False)
            release.survivor = survivor
            release.save()
            _log_action(
                request,
                AuditLog.Action.UPDATE if instance else AuditLog.Action.CREATE,
                release,
            )
            messages.success(request, _("تم حفظ بيانات الإفراج."))
            return redirect("survivors:detail", pk=survivor.pk)
    else:
        form = ReleaseEventForm(instance=instance)
    return render(request, "survivors/sub_form.html", {
        "form": form, "survivor": survivor,
        "title": _("بيانات الإفراج"), "submit_label": _("حفظ"),
    })


@login_required
def witness_add(request, pk):
    if not _check_can_document(request.user):
        return HttpResponseForbidden()
    survivor = get_object_or_404(SurvivorProfile, pk=pk)
    if request.method == "POST":
        form = WitnessForm(request.POST, request.FILES)
        if form.is_valid():
            witness = form.save(commit=False)
            witness.survivor = survivor
            witness.documenter = request.user
            witness.save()
            _log_action(request, AuditLog.Action.CREATE, witness)
            messages.success(request, _("تم إضافة الشاهد."))
            return redirect("survivors:detail", pk=survivor.pk)
    else:
        form = WitnessForm()
    return render(request, "survivors/sub_form.html", {
        "form": form, "survivor": survivor,
        "title": _("إضافة شاهد متقاطع"), "submit_label": _("حفظ"),
    })


@login_required
def document_add(request, pk):
    if not _check_can_document(request.user):
        return HttpResponseForbidden()
    survivor = get_object_or_404(SurvivorProfile, pk=pk)
    if request.method == "POST":
        form = SupportingDocumentForm(request.POST, request.FILES)
        if form.is_valid():
            doc = form.save(commit=False)
            doc.survivor = survivor
            doc.obtained_by = request.user
            doc.save()
            _log_action(request, AuditLog.Action.CREATE, doc)
            hash_preview = (doc.file_hash_sha256 or "")[:16]
            messages.success(
                request,
                _("تم رفع الوثيقة. بصمة SHA-256: %(hash)s...") % {"hash": hash_preview},
            )
            return redirect("survivors:detail", pk=survivor.pk)
    else:
        form = SupportingDocumentForm()
    return render(request, "survivors/sub_form.html", {
        "form": form, "survivor": survivor,
        "title": _("إضافة وثيقة داعمة"), "submit_label": _("رفع"),
    })


@login_required
def medical_add(request, pk):
    if not _check_can_document(request.user):
        return HttpResponseForbidden()
    survivor = get_object_or_404(SurvivorProfile, pk=pk)
    if request.method == "POST":
        form = MedicalAssessmentForm(request.POST, request.FILES)
        if form.is_valid():
            assessment = form.save(commit=False)
            assessment.survivor = survivor
            assessment.save()
            _log_action(request, AuditLog.Action.CREATE, assessment)
            messages.success(request, _("تم إضافة التقييم الطبي."))
            return redirect("survivors:detail", pk=survivor.pk)
    else:
        form = MedicalAssessmentForm()
    return render(request, "survivors/sub_form.html", {
        "form": form, "survivor": survivor,
        "title": _("إضافة تقييم طبي/نفسي"), "submit_label": _("حفظ"),
    })
