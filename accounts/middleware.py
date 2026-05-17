import logging

from django.utils.deprecation import MiddlewareMixin

audit_logger = logging.getLogger("audit")


def _get_client_ip(request):
    forwarded = request.META.get("HTTP_X_FORWARDED_FOR")
    if forwarded:
        return forwarded.split(",")[0].strip()
    return request.META.get("REMOTE_ADDR")


class AuditLogMiddleware(MiddlewareMixin):
    """يسجل كل طلب حساس (مشاهدة/تعديل/حذف) لملفات الناجين في سجل التدقيق."""

    SENSITIVE_PATHS = ("/survivors/", "/social-survey/", "/admin/")

    def process_response(self, request, response):
        path = request.path
        if not any(path.startswith(p) for p in self.SENSITIVE_PATHS):
            return response

        user = getattr(request, "user", None)
        if not user or not user.is_authenticated:
            return response

        from accounts.models import AuditLog

        method_to_action = {
            "GET": AuditLog.Action.VIEW,
            "POST": AuditLog.Action.CREATE,
            "PUT": AuditLog.Action.UPDATE,
            "PATCH": AuditLog.Action.UPDATE,
            "DELETE": AuditLog.Action.DELETE,
        }
        action = method_to_action.get(request.method, AuditLog.Action.VIEW)

        try:
            AuditLog.objects.create(
                user=user,
                action=action,
                path=path[:500],
                ip_address=_get_client_ip(request),
                user_agent=request.META.get("HTTP_USER_AGENT", "")[:500],
            )
            audit_logger.info(
                "user=%s action=%s path=%s status=%s",
                user.username, action, path, response.status_code,
            )
        except Exception:
            audit_logger.exception("Failed to write audit log")

        return response
