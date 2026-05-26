"""المصادقة بالـ Token عبر header: Authorization: Token <key>"""

from django.http import JsonResponse
from functools import wraps

from .models import AuthToken


def require_token(view_func):
    """ديكوريتور يتحقق من رمز المصادقة في الـheader."""
    @wraps(view_func)
    def wrapper(request, *args, **kwargs):
        auth_header = request.META.get("HTTP_AUTHORIZATION", "")
        if not auth_header.startswith("Token "):
            return JsonResponse(
                {"error": "missing_token", "detail": "Authorization: Token <key> مطلوب"},
                status=401,
            )
        key = auth_header[6:].strip()
        try:
            token = AuthToken.objects.select_related("user").get(
                key=key, revoked=False,
            )
        except AuthToken.DoesNotExist:
            return JsonResponse(
                {"error": "invalid_token", "detail": "الرمز غير صالح أو مُلغى"},
                status=401,
            )
        # تحديث آخر استخدام
        from django.utils import timezone
        AuthToken.objects.filter(pk=token.pk).update(last_used_at=timezone.now())
        request.api_user = token.user
        request.api_token = token
        return view_func(request, *args, **kwargs)
    return wrapper


def require_documenter(view_func):
    """يتطلب صلاحية موثّق أو أعلى."""
    @wraps(view_func)
    @require_token
    def wrapper(request, *args, **kwargs):
        user = request.api_user
        if not (user.is_superuser or user.can_document):
            return JsonResponse(
                {"error": "forbidden", "detail": "لا تملك صلاحية التوثيق"},
                status=403,
            )
        return view_func(request, *args, **kwargs)
    return wrapper
