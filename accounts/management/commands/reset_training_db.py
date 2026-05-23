"""إعادة ضبط قاعدة بيانات التدريب - حذف كل البيانات والبدء من جديد.

محمي بفحص يمنع تنفيذه على بيئة الإنتاج. يحذف فقط db.training.sqlite3
وملفات media_training/ ثم يُعيد التنصيب الكامل.

الاستخدام:
    DJANGO_MODE=training python manage.py reset_training_db
أو من المتصفّح بحساب admin:
    /admin/ → "Reset training data"
"""

import os
import shutil

from django.conf import settings
from django.core.management import call_command
from django.core.management.base import BaseCommand, CommandError


class Command(BaseCommand):
    help = "حذف كل بيانات التدريب وإعادة تنصيب نظيف. يعمل فقط في وضع التدريب."

    def add_arguments(self, parser):
        parser.add_argument(
            "--yes-i-am-sure", action="store_true",
            help="تخطّي التأكيد التفاعلي",
        )

    def handle(self, *args, **opts):
        # حماية متعددة الطبقات
        if not getattr(settings, "IS_TRAINING_MODE", False):
            raise CommandError(
                "⛔ هذا الأمر يعمل فقط في وضع التدريب (DJANGO_MODE=training). "
                "أنت حالياً في بيئة الإنتاج - الأمر مرفوض لحماية البيانات."
            )

        db_path = settings.DATABASES["default"]["NAME"]
        if "training" not in str(db_path).lower():
            raise CommandError(
                f"⛔ مسار قاعدة البيانات لا يحتوي على 'training': {db_path}. "
                "هذا قد يعني أنك في وضع غير صحيح. الأمر مرفوض."
            )

        if not opts["yes_i_am_sure"]:
            self.stdout.write(self.style.WARNING(
                f"\n⚠ سيتم حذف:\n"
                f"   - قاعدة البيانات: {db_path}\n"
                f"   - مجلد الميديا: {settings.MEDIA_ROOT}\n\n"
                f"للتأكيد، أعد التشغيل بـ --yes-i-am-sure"
            ))
            return

        # حذف قاعدة البيانات
        if os.path.exists(db_path):
            os.remove(db_path)
            self.stdout.write(self.style.SUCCESS(f"✓ حُذفت قاعدة البيانات: {db_path}"))

        # حذف مجلد الميديا
        if os.path.exists(settings.MEDIA_ROOT):
            shutil.rmtree(settings.MEDIA_ROOT)
            self.stdout.write(self.style.SUCCESS(f"✓ حُذف مجلد الميديا: {settings.MEDIA_ROOT}"))

        # إعادة التنصيب
        self.stdout.write("\nإعادة بناء قاعدة بيانات التدريب...")
        call_command("migrate", verbosity=0)
        self.stdout.write(self.style.SUCCESS("✓ تمت الترحيلات"))

        call_command("create_admin", verbosity=0)
        self.stdout.write(self.style.SUCCESS("✓ أُنشئ حساب admin/haqquna2026"))

        call_command("seed_reference_data", verbosity=0)
        self.stdout.write(self.style.SUCCESS("✓ بُذرت 27 مركز احتجاز + 33 نمط تعذيب"))

        try:
            call_command("seed_training_data", verbosity=0)
            self.stdout.write(self.style.SUCCESS("✓ بُذرت بيانات تجريبية للمتطوّعين"))
        except Exception as e:
            self.stdout.write(self.style.WARNING(f"⚠ تخطّي بذر بيانات التجريب: {e}"))

        self.stdout.write(self.style.SUCCESS(
            "\n✨ بيئة التدريب جاهزة من جديد. ابدأ التشغيل بـ ./run_training.sh"
        ))
