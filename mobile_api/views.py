"""REST API endpoints لتطبيق Flutter الجوال."""

import json

from django.contrib.auth import authenticate
from django.core.paginator import Paginator
from django.db.models import Q
from django.http import JsonResponse
from django.utils import timezone
from django.views.decorators.csrf import csrf_exempt
from django.views.decorators.http import require_http_methods

from accounts.models import AuditLog
from survivors.choices import (
    Country, InterviewLanguage, MaritalStatus, OccupationCategory,
    PoliticalActivity, SyrianGovernorate,
)
from survivors.models import (
    DetentionFacility, ReleaseEvent, SurvivorNote,
    SurvivorProfile, TortureMethod,
)
from survivors.syria_geo import SYRIA_CITIES

from .authentication import require_documenter, require_token
from .models import AuthToken, SyncBatch
from .serializers import (
    serialize_facility, serialize_survivor, serialize_torture_method,
    serialize_user,
)


# ============================================================
# المصادقة
# ============================================================

@csrf_exempt
@require_http_methods(["POST"])
def login(request):
    """POST {username, password, device_name, device_id} → {token, user}"""
    try:
        data = json.loads(request.body or b"{}")
    except json.JSONDecodeError:
        return JsonResponse({"error": "invalid_json"}, status=400)

    username = data.get("username", "").strip()
    password = data.get("password", "")
    if not username or not password:
        return JsonResponse({"error": "missing_credentials"}, status=400)

    user = authenticate(username=username, password=password)
    if not user or not user.is_active:
        AuditLog.objects.create(
            action=AuditLog.Action.FAILED_LOGIN,
            target_repr=f"محاولة دخول API فاشلة: {username}",
            ip_address=request.META.get("REMOTE_ADDR"),
        )
        return JsonResponse({"error": "invalid_credentials"}, status=401)

    token = AuthToken.generate(
        user=user,
        device_name=data.get("device_name", ""),
        device_id=data.get("device_id", ""),
    )
    AuditLog.objects.create(
        user=user, action=AuditLog.Action.LOGIN,
        target_repr=f"دخول API من {data.get('device_name', 'جوال')}",
        ip_address=request.META.get("REMOTE_ADDR"),
    )
    return JsonResponse({
        "token": token.key,
        "user": serialize_user(user),
    })


@csrf_exempt
@require_token
@require_http_methods(["POST"])
def logout(request):
    request.api_token.revoked = True
    request.api_token.save()
    return JsonResponse({"ok": True})


@require_token
@require_http_methods(["GET"])
def profile(request):
    return JsonResponse({"user": serialize_user(request.api_user)})


# ============================================================
# البيانات المرجعية
# ============================================================

@require_token
@require_http_methods(["GET"])
def reference_data(request):
    """كل البيانات المرجعية (يُحمَّل مرة ويُكاش محلياً)."""
    return JsonResponse({
        "facilities": [
            serialize_facility(f) for f in DetentionFacility.objects.all()
        ],
        "torture_methods": [
            serialize_torture_method(t) for t in TortureMethod.objects.all()
        ],
        "choices": {
            "syrian_governorates": [
                {"value": v, "label": str(l)} for v, l in SyrianGovernorate.CHOICES
            ],
            "countries": [
                {"value": v, "label": str(l)} for v, l in Country.CHOICES
            ],
            "occupations": [
                {"value": v, "label": str(l)} for v, l in OccupationCategory.CHOICES
            ],
            "political_activities": [
                {"value": v, "label": str(l)}
                for v, l in PoliticalActivity.CHOICES
            ],
            "marital_statuses": [
                {"value": v, "label": str(l)} for v, l in MaritalStatus.CHOICES
            ],
            "interview_languages": [
                {"value": v, "label": str(l)}
                for v, l in InterviewLanguage.CHOICES
            ],
            "genders": [
                {"value": v, "label": str(l)}
                for v, l in SurvivorProfile.Gender.choices
            ],
            "file_classifications": [
                {"value": v, "label": str(l)}
                for v, l in SurvivorProfile.FileClassification.choices
            ],
            "release_types": [
                {"value": v, "label": str(l)}
                for v, l in ReleaseEvent.ReleaseType.choices
            ],
            "note_types": [
                {"value": v, "label": str(l)}
                for v, l in SurvivorNote.NoteType.choices
            ],
        },
        "syria_geo": SYRIA_CITIES,
        "server_time": timezone.now().isoformat(),
    })


# ============================================================
# الناجون CRUD
# ============================================================

@require_token
@require_http_methods(["GET"])
def survivor_list(request):
    qs = SurvivorProfile.objects.select_related("documenter").order_by("-created_at")
    q = request.GET.get("q", "").strip()
    if q:
        qs = qs.filter(
            Q(case_reference__icontains=q)
            | Q(first_name__icontains=q)
            | Q(father_name__icontains=q)
            | Q(family_name__icontains=q)
            | Q(national_id__icontains=q)
            | Q(alias__icontains=q)
        )
    for param, field in [
        ("classification", "file_classification"),
        ("gender", "gender"),
        ("governorate", "governorate_at_detention"),
    ]:
        val = request.GET.get(param, "")
        if val:
            qs = qs.filter(**{field: val})

    page_size = min(int(request.GET.get("page_size", 50)), 200)
    page_num = int(request.GET.get("page", 1))
    paginator = Paginator(qs, page_size)
    page = paginator.get_page(page_num)
    return JsonResponse({
        "results": [serialize_survivor(s) for s in page],
        "count": paginator.count,
        "num_pages": paginator.num_pages,
        "current_page": page.number,
        "has_next": page.has_next(),
        "has_previous": page.has_previous(),
    })


@require_token
@require_http_methods(["GET"])
def survivor_detail(request, pk):
    try:
        s = SurvivorProfile.all_objects.get(pk=pk)
    except SurvivorProfile.DoesNotExist:
        return JsonResponse({"error": "not_found"}, status=404)
    return JsonResponse(serialize_survivor(s, detail=True))


SURVIVOR_WRITABLE = {
    "case_reference", "first_name", "father_name", "grandfather_name",
    "family_name", "mother_name", "alias", "national_id",
    "birth_date", "birth_date_approximate", "birth_governorate",
    "birth_place_detail", "gender", "nationality",
    "marital_status_at_detention", "address_at_detention",
    "governorate_at_detention", "occupation_category",
    "occupation_detail", "political_activity_category",
    "political_activity_detail", "current_phone", "current_email",
    "current_country", "current_governorate", "current_city",
    "next_of_kin_name", "next_of_kin_relation", "next_of_kin_phone",
    "file_classification",
}


@csrf_exempt
@require_documenter
@require_http_methods(["POST"])
def survivor_create(request):
    try:
        data = json.loads(request.body or b"{}")
    except json.JSONDecodeError:
        return JsonResponse({"error": "invalid_json"}, status=400)

    required = ["case_reference", "first_name", "father_name", "family_name", "gender"]
    missing = [f for f in required if not data.get(f)]
    if missing:
        return JsonResponse({"error": "missing_fields", "fields": missing}, status=400)

    if SurvivorProfile.all_objects.filter(case_reference=data["case_reference"]).exists():
        return JsonResponse({
            "error": "duplicate_case_reference",
            "detail": "رقم القضية موجود مسبقاً",
        }, status=409)

    clean = {k: v for k, v in data.items() if k in SURVIVOR_WRITABLE and v is not None}
    try:
        survivor = SurvivorProfile.objects.create(
            **clean, documenter=request.api_user,
        )
    except Exception as e:
        return JsonResponse({"error": "create_failed", "detail": str(e)}, status=400)

    AuditLog.objects.create(
        user=request.api_user, action=AuditLog.Action.CREATE,
        target_model="SurvivorProfile", target_id=str(survivor.pk),
        target_repr=f"API إنشاء {survivor.case_reference}",
        ip_address=request.META.get("REMOTE_ADDR"),
    )
    return JsonResponse(serialize_survivor(survivor, detail=True), status=201)


@csrf_exempt
@require_documenter
@require_http_methods(["PUT", "PATCH"])
def survivor_update(request, pk):
    try:
        survivor = SurvivorProfile.all_objects.get(pk=pk)
    except SurvivorProfile.DoesNotExist:
        return JsonResponse({"error": "not_found"}, status=404)
    try:
        data = json.loads(request.body or b"{}")
    except json.JSONDecodeError:
        return JsonResponse({"error": "invalid_json"}, status=400)

    for k, v in data.items():
        if k in SURVIVOR_WRITABLE:
            setattr(survivor, k, v)
    survivor.save()

    AuditLog.objects.create(
        user=request.api_user, action=AuditLog.Action.UPDATE,
        target_model="SurvivorProfile", target_id=str(survivor.pk),
        target_repr=f"API تعديل {survivor.case_reference}",
        ip_address=request.META.get("REMOTE_ADDR"),
    )
    return JsonResponse(serialize_survivor(survivor, detail=True))


# ============================================================
# المزامنة المجمّعة
# ============================================================

@csrf_exempt
@require_documenter
@require_http_methods(["POST"])
def sync_push(request):
    """دفع تغييرات الجوال للسيرفر دفعة واحدة."""
    try:
        payload = json.loads(request.body or b"{}")
    except json.JSONDecodeError:
        return JsonResponse({"error": "invalid_json"}, status=400)

    survivors_in = payload.get("survivors", [])
    device_id = payload.get("device_id", "")

    batch = SyncBatch.objects.create(
        user=request.api_user, device_id=device_id,
        direction="push", records_count=len(survivors_in),
    )
    results = []
    success = 0
    errors_log = []

    for item in survivors_in:
        local_id = item.get("_local_id")
        clean = {
            k: v for k, v in item.items()
            if k in SURVIVOR_WRITABLE and v is not None
        }
        case_ref = clean.get("case_reference", "")
        try:
            existing = SurvivorProfile.all_objects.filter(
                case_reference=case_ref,
            ).first()
            if existing:
                for k, v in clean.items():
                    setattr(existing, k, v)
                existing.save()
                survivor = existing
                action = "updated"
            else:
                survivor = SurvivorProfile.objects.create(
                    **clean, documenter=request.api_user,
                )
                action = "created"
            results.append({
                "_local_id": local_id,
                "server_id": survivor.id,
                "case_reference": survivor.case_reference,
                "action": action,
                "ok": True,
            })
            success += 1
        except Exception as e:
            results.append({
                "_local_id": local_id,
                "case_reference": case_ref,
                "ok": False,
                "error": str(e)[:200],
            })
            errors_log.append({"case_reference": case_ref, "error": str(e)[:200]})

    batch.success_count = success
    batch.error_count = len(survivors_in) - success
    batch.errors = errors_log
    batch.save()
    return JsonResponse({
        "batch_id": batch.id,
        "results": results,
        "success": success,
        "errors": len(survivors_in) - success,
        "server_time": timezone.now().isoformat(),
    })


@require_token
@require_http_methods(["GET"])
def sync_pull(request):
    """سحب التغييرات منذ timestamp معين."""
    since_str = request.GET.get("since", "")
    qs = SurvivorProfile.objects.select_related("documenter")
    if since_str:
        from django.utils.dateparse import parse_datetime
        try:
            since = parse_datetime(since_str)
            if since:
                qs = qs.filter(updated_at__gte=since)
        except Exception:
            pass
    qs = qs.order_by("updated_at")
    page_size = min(int(request.GET.get("page_size", 100)), 500)
    page_num = int(request.GET.get("page", 1))
    paginator = Paginator(qs, page_size)
    page = paginator.get_page(page_num)
    return JsonResponse({
        "survivors": [serialize_survivor(s, detail=True) for s in page],
        "count": paginator.count,
        "num_pages": paginator.num_pages,
        "current_page": page.number,
        "has_next": page.has_next(),
        "server_time": timezone.now().isoformat(),
    })
