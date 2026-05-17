from django.contrib import messages
from django.contrib.auth.decorators import login_required
from django.core.paginator import Paginator
from django.db.models import Count, Q
from django.http import HttpResponseForbidden
from django.shortcuts import get_object_or_404, redirect, render
from django.utils.translation import gettext_lazy as _

from accounts.models import AuditLog

from .forms import (
    DetentionEventForm, DetentionPeriodForm, InformedConsentForm,
    InterviewForm, InterviewMediaForm, MedicalAssessmentForm,
    ReleaseEventForm, SupportingDocumentForm, SurvivorContactForm,
    SurvivorNoteForm, SurvivorPhotosForm, SurvivorProfileForm,
    SurvivorReferralsForm, SurvivorSearchForm, WitnessForm,
)
from .models import (
    InformedConsent, Interview, InterviewMedia, SurvivorNote, SurvivorProfile,
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


def _apply_survivor_filters(qs, cleaned):
    """يطبّق نموذج البحث على QuerySet."""
    if not cleaned:
        return qs

    q = cleaned.get("q")
    if q:
        qs = qs.filter(
            Q(case_reference__icontains=q)
            | Q(first_name__icontains=q)
            | Q(father_name__icontains=q)
            | Q(grandfather_name__icontains=q)
            | Q(family_name__icontains=q)
            | Q(mother_name__icontains=q)
            | Q(national_id__icontains=q)
            | Q(alias__icontains=q)
        )

    # حقول مباشرة
    direct_filters = [
        "classification:file_classification", "gender:gender",
        "marital_status_at_detention:marital_status_at_detention",
        "governorate_at_detention:governorate_at_detention",
        "birth_governorate:birth_governorate",
        "current_country:current_country",
        "current_governorate:current_governorate",
        "occupation_category:occupation_category",
        "political_activity_category:political_activity_category",
    ]
    for spec in direct_filters:
        form_key, field_key = spec.split(":")
        val = cleaned.get(form_key)
        if val:
            qs = qs.filter(**{field_key: val})

    # فرع/منشأة معينة
    facility = cleaned.get("facility")
    if facility:
        qs = qs.filter(detention_periods__facility=facility)

    # نمط تعذيب معين
    torture = cleaned.get("torture_method")
    if torture:
        qs = qs.filter(detention_periods__torture_methods=torture)

    # عنف جنسي
    sv = cleaned.get("sexual_violence_reported")
    if sv == "yes":
        qs = qs.filter(detention_periods__sexual_violence_reported=True)
    elif sv == "no":
        qs = qs.exclude(detention_periods__sexual_violence_reported=True)

    # نطاقات تاريخية
    if cleaned.get("detention_from"):
        qs = qs.filter(detention_events__detention_date__gte=cleaned["detention_from"])
    if cleaned.get("detention_to"):
        qs = qs.filter(detention_events__detention_date__lte=cleaned["detention_to"])
    if cleaned.get("created_from"):
        qs = qs.filter(created_at__date__gte=cleaned["created_from"])
    if cleaned.get("created_to"):
        qs = qs.filter(created_at__date__lte=cleaned["created_to"])

    # حد أدنى للدرجة الإجمالية - نطبقها بحساب يدوي بعد التصفية
    min_score = cleaned.get("min_overall_score")
    if min_score is not None:
        # تقدير: (r + c + co) / 3 >= min_score ⟹ r + c + co >= 3*min
        from django.db.models import F
        threshold = float(min_score) * 3
        qs = qs.annotate(
            _sum=F("reliability_score") + F("corroboration_score") + F("completeness_score")
        ).filter(_sum__gte=threshold)

    # موافقات
    has_consent = cleaned.get("has_consent")
    if has_consent == "yes":
        qs = qs.filter(
            consent__consent_documented=True,
            consent__withdrawal_right_explained=True,
            consent__confidentiality_limits_explained=True,
            consent__intended_uses_explained=True,
            consent__consent_withdrawn=False,
        )
    elif has_consent == "no":
        qs = qs.filter(
            Q(consent__isnull=True)
            | Q(consent__consent_documented=False)
            | Q(consent__consent_withdrawn=True)
        )

    if cleaned.get("consent_iiim") == "yes":
        qs = qs.filter(consent__share_with_iiim=True)
    elif cleaned.get("consent_iiim") == "no":
        qs = qs.exclude(consent__share_with_iiim=True)

    if cleaned.get("consent_icc") == "yes":
        qs = qs.filter(consent__share_with_icc=True)
    elif cleaned.get("consent_icc") == "no":
        qs = qs.exclude(consent__share_with_icc=True)

    # تقييم طبي
    hm = cleaned.get("has_medical_assessment")
    if hm == "yes":
        qs = qs.filter(medical_assessments__isnull=False)
    elif hm == "istanbul":
        qs = qs.filter(medical_assessments__istanbul_protocol_compliant=True)
    elif hm == "no":
        qs = qs.filter(medical_assessments__isnull=True)

    # فيديو
    hv = cleaned.get("has_video")
    if hv == "yes":
        qs = qs.filter(
            Q(interviews__media__media_type__in=["video", "audio"])
            | Q(documents__document_type__in=["video", "audio"])
        )
    elif hv == "no":
        qs = qs.exclude(
            Q(interviews__media__media_type__in=["video", "audio"])
            | Q(documents__document_type__in=["video", "audio"])
        )

    # شهود مستقلون
    min_w = cleaned.get("min_witnesses")
    if min_w:
        qs = qs.annotate(
            _ind_witnesses=Count(
                "witnesses",
                filter=Q(witnesses__is_independent=True,
                         witnesses__consent_to_use_testimony=True),
                distinct=True,
            )
        ).filter(_ind_witnesses__gte=min_w)

    return qs.distinct()


@login_required
def survivor_list(request):
    form = SurvivorSearchForm(request.GET or None)
    qs = SurvivorProfile.objects.select_related("documenter").order_by("-created_at")

    if form.is_valid():
        qs = _apply_survivor_filters(qs, form.cleaned_data)
    elif not form.is_bound:
        pass

    total = qs.count()
    paginator = Paginator(qs, 25)
    page = paginator.get_page(request.GET.get("page"))

    # نمرّر سلسلة الـquerystring (بدون page) للاستخدام في pagination والـexport
    qs_params = request.GET.copy()
    qs_params.pop("page", None)
    querystring = qs_params.urlencode()

    return render(request, "survivors/list.html", {
        "form": form, "page": page, "total": total,
        "querystring": querystring,
    })


@login_required
def survivor_detail(request, pk):
    survivor = get_object_or_404(SurvivorProfile, pk=pk)
    _log_action(request, AuditLog.Action.VIEW, survivor)
    # نُحدّث الدرجات عند كل اطلاع لتعكس البيانات الحالية
    survivor.recompute_scores(save=True)
    survivor.refresh_from_db()

    # فلترة الملاحظات حسب صلاحية الوصول للسرّية
    notes_qs = survivor.notes.select_related("author")
    if not (request.user.is_superuser or request.user.can_view_sensitive):
        notes_qs = notes_qs.filter(is_confidential=False)

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
        "notes": notes_qs,
        "interviews": survivor.interviews.prefetch_related("media").all(),
        "breakdowns": survivor.all_breakdowns(),
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


# ============================================================
# الملاحظات (Notes)
# ============================================================

@login_required
def note_add(request, pk):
    if not _check_can_document(request.user):
        return HttpResponseForbidden()
    survivor = get_object_or_404(SurvivorProfile, pk=pk)
    if request.method == "POST":
        form = SurvivorNoteForm(request.POST)
        if form.is_valid():
            note = form.save(commit=False)
            note.survivor = survivor
            note.author = request.user
            note.save()
            _log_action(request, AuditLog.Action.CREATE, note)
            messages.success(request, _("تمت إضافة الملاحظة."))
            return redirect("survivors:detail", pk=survivor.pk)
    else:
        form = SurvivorNoteForm()
    return render(request, "survivors/sub_form.html", {
        "form": form, "survivor": survivor,
        "title": _("إضافة ملاحظة"), "submit_label": _("حفظ"),
    })


@login_required
def note_edit(request, pk):
    note = get_object_or_404(SurvivorNote, pk=pk)
    if not _check_can_document(request.user):
        return HttpResponseForbidden()
    if request.method == "POST":
        form = SurvivorNoteForm(request.POST, instance=note)
        if form.is_valid():
            form.save()
            _log_action(request, AuditLog.Action.UPDATE, note)
            messages.success(request, _("تم حفظ التعديلات."))
            return redirect("survivors:detail", pk=note.survivor.pk)
    else:
        form = SurvivorNoteForm(instance=note)
    return render(request, "survivors/sub_form.html", {
        "form": form, "survivor": note.survivor,
        "title": _("تعديل ملاحظة"), "submit_label": _("حفظ"),
    })


@login_required
def note_delete(request, pk):
    note = get_object_or_404(SurvivorNote, pk=pk)
    if not _check_can_document(request.user):
        return HttpResponseForbidden()
    if request.method == "POST":
        survivor_pk = note.survivor.pk
        _log_action(request, AuditLog.Action.DELETE, note)
        note.delete()
        messages.success(request, _("تم حذف الملاحظة."))
        return redirect("survivors:detail", pk=survivor_pk)
    return render(request, "survivors/note_delete_confirm.html", {"note": note})


# ============================================================
# المقابلات والوسائط (Interviews & Media)
# ============================================================

@login_required
def interview_add(request, pk):
    if not _check_can_document(request.user):
        return HttpResponseForbidden()
    survivor = get_object_or_404(SurvivorProfile, pk=pk)
    next_seq = (survivor.interviews.count() or 0) + 1
    if request.method == "POST":
        form = InterviewForm(request.POST)
        if form.is_valid():
            interview = form.save(commit=False)
            interview.survivor = survivor
            interview.interviewer = request.user
            interview.save()
            _log_action(request, AuditLog.Action.CREATE, interview)
            messages.success(request, _("تم إضافة المقابلة. أضف الفيديوهات/الملفات الآن."))
            return redirect("survivors:interview_detail", pk=interview.pk)
    else:
        form = InterviewForm(initial={
            "sequence_number": next_seq,
            "is_first": next_seq == 1,
        })
    return render(request, "survivors/sub_form.html", {
        "form": form, "survivor": survivor,
        "title": _("إضافة مقابلة جديدة"), "submit_label": _("حفظ"),
    })


@login_required
def interview_detail(request, pk):
    interview = get_object_or_404(Interview, pk=pk)
    _log_action(request, AuditLog.Action.VIEW, interview)
    return render(request, "survivors/interview_detail.html", {
        "interview": interview,
        "survivor": interview.survivor,
        "media": interview.media.all(),
    })


@login_required
def interview_edit(request, pk):
    interview = get_object_or_404(Interview, pk=pk)
    if not _check_can_document(request.user):
        return HttpResponseForbidden()
    if request.method == "POST":
        form = InterviewForm(request.POST, instance=interview)
        if form.is_valid():
            form.save()
            _log_action(request, AuditLog.Action.UPDATE, interview)
            messages.success(request, _("تم حفظ التعديلات."))
            return redirect("survivors:interview_detail", pk=interview.pk)
    else:
        form = InterviewForm(instance=interview)
    return render(request, "survivors/sub_form.html", {
        "form": form, "survivor": interview.survivor,
        "title": _("تعديل المقابلة"), "submit_label": _("حفظ"),
    })


@login_required
def media_add(request, interview_pk):
    interview = get_object_or_404(Interview, pk=interview_pk)
    if not _check_can_document(request.user):
        return HttpResponseForbidden()
    if request.method == "POST":
        form = InterviewMediaForm(request.POST, request.FILES)
        if form.is_valid():
            media = form.save(commit=False)
            media.interview = interview
            media.uploaded_by = request.user
            media.save()
            _log_action(request, AuditLog.Action.CREATE, media)
            messages.success(
                request,
                _("تم رفع الملف. بصمة SHA-256: %(h)s...") % {"h": media.file_hash_sha256[:16]},
            )
            return redirect("survivors:interview_detail", pk=interview.pk)
    else:
        form = InterviewMediaForm()
    return render(request, "survivors/sub_form.html", {
        "form": form, "survivor": interview.survivor,
        "title": _("رفع فيديو/صوت/ملف للمقابلة #%(n)s") % {"n": interview.sequence_number},
        "submit_label": _("رفع"),
    })


@login_required
def media_delete(request, pk):
    media = get_object_or_404(InterviewMedia, pk=pk)
    if not _check_can_document(request.user):
        return HttpResponseForbidden()
    if request.method == "POST":
        interview_pk = media.interview.pk
        _log_action(request, AuditLog.Action.DELETE, media)
        media.delete()
        messages.success(request, _("تم حذف الملف."))
        return redirect("survivors:interview_detail", pk=interview_pk)
    return render(request, "survivors/media_delete_confirm.html", {"media": media})


# ============================================================
# الأقسام الفرعية للملف الأساسي (Contact, Photos, Referrals)
# ============================================================

def _generic_section_edit(request, pk, form_class, title):
    if not _check_can_document(request.user):
        return HttpResponseForbidden()
    survivor = get_object_or_404(SurvivorProfile, pk=pk)
    if request.method == "POST":
        form = form_class(request.POST, request.FILES, instance=survivor)
        if form.is_valid():
            form.save()
            _log_action(request, AuditLog.Action.UPDATE, survivor)
            messages.success(request, _("تم حفظ التعديلات."))
            return redirect("survivors:detail", pk=survivor.pk)
    else:
        form = form_class(instance=survivor)
    return render(request, "survivors/sub_form.html", {
        "form": form, "survivor": survivor,
        "title": title, "submit_label": _("حفظ"),
    })


@login_required
def contact_edit(request, pk):
    return _generic_section_edit(
        request, pk, SurvivorContactForm,
        _("معلومات الاتصال والقريب"),
    )


@login_required
def photos_edit(request, pk):
    return _generic_section_edit(
        request, pk, SurvivorPhotosForm, _("صور الناجي"),
    )


@login_required
def referrals_edit(request, pk):
    return _generic_section_edit(
        request, pk, SurvivorReferralsForm,
        _("الإحالات الطبية والنفسية والقانونية"),
    )
