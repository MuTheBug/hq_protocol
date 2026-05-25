"""URL configuration for hq_protocol project - جمعية حقّنا."""

from django.conf import settings
from django.conf.urls.static import static
from django.contrib import admin
from django.urls import include, path
from django.views.generic import TemplateView
from django.views.static import serve

urlpatterns = [
    path("admin/", admin.site.urls),
    # PWA: تقديم sw.js و manifest.json على المسار الجذري (متطلب SW scope)
    path("sw.js", serve, {
        "path": "sw.js",
        "document_root": settings.BASE_DIR / "static",
    }),
    path("manifest.json", serve, {
        "path": "manifest.json",
        "document_root": settings.BASE_DIR / "static",
    }),
    path("accounts/", include("accounts.urls")),
    path("survivors/", include("survivors.urls")),
    path("social-survey/", include("social_survey.urls")),
    path("tutorials/", include("tutorials.urls")),
    path("", include("core.urls")),
]

if settings.DEBUG:
    urlpatterns += static(settings.STATIC_URL, document_root=settings.STATIC_ROOT)
    urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)
