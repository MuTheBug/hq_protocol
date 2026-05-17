from django.contrib import messages
from django.contrib.auth import login, logout
from django.contrib.auth.decorators import login_required
from django.contrib.auth.views import LoginView, LogoutView
from django.shortcuts import redirect, render
from django.urls import reverse_lazy
from django.utils.translation import gettext_lazy as _

from .forms import LoginForm, UserProfileForm, UserRegistrationForm
from .models import AuditLog, User


class CustomLoginView(LoginView):
    template_name = "accounts/login.html"
    authentication_form = LoginForm
    redirect_authenticated_user = True

    def form_valid(self, form):
        response = super().form_valid(form)
        AuditLog.objects.create(
            user=self.request.user,
            action=AuditLog.Action.LOGIN,
            ip_address=self.request.META.get("REMOTE_ADDR"),
            user_agent=self.request.META.get("HTTP_USER_AGENT", "")[:500],
        )
        return response

    def form_invalid(self, form):
        username = form.cleaned_data.get("username") or self.request.POST.get("username", "")
        AuditLog.objects.create(
            user=User.objects.filter(username=username).first(),
            action=AuditLog.Action.FAILED_LOGIN,
            ip_address=self.request.META.get("REMOTE_ADDR"),
            user_agent=self.request.META.get("HTTP_USER_AGENT", "")[:500],
            notes=f"محاولة دخول فاشلة باسم: {username}",
        )
        return super().form_invalid(form)


class CustomLogoutView(LogoutView):
    next_page = reverse_lazy("accounts:login")

    def dispatch(self, request, *args, **kwargs):
        if request.user.is_authenticated:
            AuditLog.objects.create(
                user=request.user,
                action=AuditLog.Action.LOGOUT,
                ip_address=request.META.get("REMOTE_ADDR"),
            )
        return super().dispatch(request, *args, **kwargs)


@login_required
def register_user(request):
    if request.user.role != User.Role.ADMIN and not request.user.is_superuser:
        messages.error(request, _("لا تملك صلاحية إنشاء مستخدمين."))
        return redirect("core:dashboard")

    if request.method == "POST":
        form = UserRegistrationForm(request.POST)
        if form.is_valid():
            new_user = form.save()
            messages.success(
                request,
                _("تم إنشاء حساب %(name)s بنجاح.") % {"name": new_user},
            )
            return redirect("accounts:user_list")
    else:
        form = UserRegistrationForm()
    return render(request, "accounts/register.html", {"form": form})


@login_required
def user_list(request):
    if not request.user.can_review and not request.user.is_superuser:
        messages.error(request, _("لا تملك صلاحية الاطلاع على قائمة المستخدمين."))
        return redirect("core:dashboard")
    users = User.objects.all().order_by("role", "username")
    return render(request, "accounts/user_list.html", {"users": users})


@login_required
def profile(request):
    if request.method == "POST":
        form = UserProfileForm(request.POST, instance=request.user)
        if form.is_valid():
            form.save()
            messages.success(request, _("تم تحديث ملفك الشخصي بنجاح."))
            return redirect("accounts:profile")
    else:
        form = UserProfileForm(instance=request.user)
    return render(request, "accounts/profile.html", {"form": form})


@login_required
def audit_log_view(request):
    if not (request.user.is_superuser or request.user.role in {
        User.Role.ADMIN, User.Role.PROTECTION, User.Role.SUPERVISOR,
    }):
        messages.error(request, _("لا تملك صلاحية الاطلاع على سجل التدقيق."))
        return redirect("core:dashboard")
    logs = AuditLog.objects.select_related("user").all()[:500]
    return render(request, "accounts/audit_log.html", {"logs": logs})
