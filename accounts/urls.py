from django.urls import path

from . import views

app_name = "accounts"

urlpatterns = [
    path("login/", views.CustomLoginView.as_view(), name="login"),
    path("logout/", views.CustomLogoutView.as_view(), name="logout"),
    path("register/", views.register_user, name="register"),
    path("users/", views.user_list, name="user_list"),
    path("profile/", views.profile, name="profile"),
    path("audit-log/", views.audit_log_view, name="audit_log"),
]
