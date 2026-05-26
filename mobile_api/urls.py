from django.urls import path

from . import views

app_name = "mobile_api"

urlpatterns = [
    # المصادقة
    path("auth/login/", views.login, name="login"),
    path("auth/logout/", views.logout, name="logout"),
    path("auth/profile/", views.profile, name="profile"),
    # البيانات المرجعية
    path("reference/", views.reference_data, name="reference"),
    # الناجون
    path("survivors/", views.survivor_list, name="survivor_list"),
    path("survivors/create/", views.survivor_create, name="survivor_create"),
    path("survivors/<int:pk>/", views.survivor_detail, name="survivor_detail"),
    path("survivors/<int:pk>/update/", views.survivor_update, name="survivor_update"),
    # المزامنة
    path("sync/push/", views.sync_push, name="sync_push"),
    path("sync/pull/", views.sync_pull, name="sync_pull"),
]
