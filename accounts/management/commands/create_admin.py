"""ينشئ حساب المسؤول الأولي لجمعية حقّنا.

الاستخدام:
    python manage.py create_admin                          # admin / haqquna2026
    python manage.py create_admin --password mySecret123   # كلمة مرور مخصصة
    python manage.py create_admin --username super --password ...
"""

from django.core.management.base import BaseCommand

from accounts.models import User


class Command(BaseCommand):
    help = "ينشئ حساب المسؤول الأولي (admin/haqquna2026) أو يُعيد ضبط كلمة المرور."

    def add_arguments(self, parser):
        parser.add_argument("--username", default="admin")
        parser.add_argument("--password", default="haqquna2026")
        parser.add_argument("--email", default="admin@haqquna.org")
        parser.add_argument("--full-name", default="مدير النظام")

    def handle(self, *args, **opts):
        username = opts["username"]
        password = opts["password"]

        user, created = User.objects.get_or_create(
            username=username,
            defaults={
                "email": opts["email"],
                "full_name_ar": opts["full_name"],
                "role": User.Role.ADMIN,
                "is_staff": True,
                "is_superuser": True,
                "is_active": True,
            },
        )
        user.set_password(password)
        user.is_staff = True
        user.is_superuser = True
        user.is_active = True
        user.role = User.Role.ADMIN
        user.save()

        action = "أُنشئ" if created else "أُعيد ضبط كلمة مروره"
        self.stdout.write(self.style.SUCCESS(
            f"✓ المستخدم '{username}' {action} بنجاح."
        ))
        self.stdout.write(self.style.WARNING(
            f"  كلمة المرور: {password}"
        ))
        self.stdout.write(self.style.WARNING(
            "  ⚠ بدّل كلمة المرور فور تسجيل الدخول الأول."
        ))
