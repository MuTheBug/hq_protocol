"""بذر بيانات تجريبية لبيئة التدريب - 3 ناجين بمستويات مختلفة.

محمي بفحص IS_TRAINING_MODE - لن يعمل إلا في وضع التدريب.

السيناريوهات الثلاثة:
1. ملف مكتمل (فئة A) - للممارسة على الإحالة والتصدير
2. ملف جزئي - للممارسة على رفع الدرجات
3. ملف مسودة - للممارسة على التوثيق من البداية
"""

from datetime import date

from django.conf import settings
from django.core.management.base import BaseCommand, CommandError


class Command(BaseCommand):
    help = "بذر بيانات تجريبية لبيئة التدريب فقط."

    def handle(self, *args, **opts):
        if not getattr(settings, "IS_TRAINING_MODE", False):
            raise CommandError(
                "⛔ بذر بيانات التدريب يعمل فقط في وضع التدريب. "
                "في الإنتاج، البيانات حقيقية ولا تُبذر تلقائياً."
            )

        from accounts.models import User
        from survivors.models import (
            DetentionEvent, DetentionFacility, DetentionPeriod,
            InformedConsent, Interview, ReleaseEvent, SupportingDocument,
            SurvivorNote, SurvivorProfile, Witness,
        )

        admin = User.objects.filter(is_superuser=True).first()
        if not admin:
            self.stderr.write("⚠ لا يوجد admin. شغّل create_admin أولاً.")
            return

        facility = DetentionFacility.objects.filter(branch_number="215").first() or \
                   DetentionFacility.objects.first()

        # ============================================================
        # سيناريو 1: ملف مكتمل بدرجة عالية (للممارسة على الإحالة)
        # ============================================================
        if not SurvivorProfile.all_objects.filter(case_reference="TRN-2026-A001").exists():
            s1 = SurvivorProfile.objects.create(
                case_reference="TRN-2026-A001",
                first_name="سامي", father_name="أحمد",
                grandfather_name="محمود", family_name="التجريبي",
                mother_name="فاطمة الزهرة", alias="أبو أحمد",
                national_id="01234567890",
                birth_date=date(1985, 5, 15), birth_governorate="damascus",
                birth_place_detail="حي الميدان",
                gender="male", nationality="سورية",
                marital_status_at_detention="married",
                governorate_at_detention="rural_damascus",
                address_at_detention="داريا، حي وسط البلد",
                occupation_category="teacher",
                occupation_detail="مدرّس فيزياء في الثانوية",
                political_activity_category="peaceful_protest",
                political_activity_detail="شارك في الاحتجاجات السلمية في 2011-2012",
                current_country="TR", current_city="غازي عنتاب",
                current_phone="+90 555 123 4567",
                next_of_kin_name="محمد التجريبي", next_of_kin_relation="أخ",
                file_classification="A", documenter=admin,
                medical_referral_offered=True,
                psychological_referral_offered=True,
                legal_aid_offered=True,
            )
            InformedConsent.objects.create(
                survivor=s1, consent_documented=True,
                consent_date=date(2026, 4, 10),
                consent_witness="د. خالد العلي",
                share_with_iiim=True, share_with_coi=True, share_with_icc=True,
                share_with_universal_jurisdiction=True,
                withdrawal_right_explained=True,
                confidentiality_limits_explained=True,
                intended_uses_explained=True,
            )
            DetentionEvent.objects.create(
                survivor=s1, detention_date=date(2018, 3, 15),
                detention_location="حاجز عسكري على طريق دمشق-داريا",
                governorate="rural_damascus",
                arresting_entity="المخابرات العسكرية - فرع 215 - كفرسوسة",
                circumstances=(
                    "تم إيقاف سامي على حاجز عسكري في الساعة العاشرة صباحاً وهو "
                    "عائد من عمله. عناصر الحاجز كانوا بزيّ الجيش، وأحدهم برتبة "
                    "رائد قاد التحقيق المبدئي على الحاجز لأكثر من ساعتين قبل "
                    "نقله مكبلاً وعصب عينيه إلى فرع 215."
                ),
                reason_stated="مشتبه بنشاط معارض",
                family_notified=False,
            )
            DetentionPeriod.objects.create(
                survivor=s1, facility=facility,
                from_date=date(2018, 3, 15), to_date=date(2019, 1, 20),
                order_index=1, cellmates_count=85,
                torture_description=(
                    "تعرّض سامي يومياً لجلسات تعذيب متكررة شملت الضرب بالكابلات "
                    "الكهربائية على القدمين (الفلقة) لأكثر من ساعة في الجلسة، وتم "
                    "تعليقه من يديه لساعات طويلة في وضعية الشبح لمدة ثلاثة أيام "
                    "متواصلة. كما تم إخضاعه للصعق الكهربائي. الزنزانة كانت بحجم "
                    "2×3 متر تضم أكثر من 80 محتجزاً في وقت واحد، الطعام مرة واحدة "
                    "يومياً (نصف رغيف خبز ومرق)، والحرمان من الحمام كان عقوبة شائعة."
                ),
                sexual_violence_reported=False,
            )
            ReleaseEvent.objects.create(
                survivor=s1, release_date=date(2019, 1, 20),
                release_type="amnesty", release_location="عدرا",
                circumstances="أُفرج عنه ضمن عفو عام دون شروط مكتوبة.",
            )
            Witness.objects.create(
                survivor=s1, witness_name="عمر القاضي",
                witness_phone="+90 555 988 7766",
                facility_witnessed_at=facility,
                period_from=date(2018, 5, 1), period_to=date(2018, 12, 15),
                how_recognized="كنا في نفس الزنزانة لمدة 7 أشهر",
                is_independent=True, consent_to_use_testimony=True,
                declaration_signed=True, declaration_date=date(2026, 4, 12),
                full_testimony="شاهدتُ سامي يتعرّض للتعذيب يومياً في فرع 215.",
                documenter=admin,
            )
            Witness.objects.create(
                survivor=s1, witness_name="نضال الحلبي",
                facility_witnessed_at=facility,
                period_from=date(2018, 8, 1),
                how_recognized="انتقلنا للزنزانة نفسها في أغسطس",
                is_independent=True, consent_to_use_testimony=True,
                declaration_signed=True,
                full_testimony="رأيتُ سامي بعد جلسات تعذيب عدة مرات.",
                documenter=admin,
            )
            Interview.objects.create(
                survivor=s1, sequence_number=1, is_first=True,
                interview_date=date(2026, 4, 15), duration_minutes=120,
                location_type="office", interviewer=admin,
                language="ar_levantine", methodology="istanbul",
                recorded=True, consent_to_record=True,
                summary="مقابلة كاملة وفق بروتوكول إسطنبول.",
            )
            self.stdout.write(self.style.SUCCESS(f"✓ ملف تجريبي مكتمل: {s1}"))

        # ============================================================
        # سيناريو 2: ملف جزئي (للممارسة على رفع الدرجات)
        # ============================================================
        if not SurvivorProfile.all_objects.filter(case_reference="TRN-2026-B001").exists():
            s2 = SurvivorProfile.objects.create(
                case_reference="TRN-2026-B001",
                first_name="ليلى", father_name="عبد الله",
                family_name="التجريبية", gender="female",
                birth_governorate="aleppo", governorate_at_detention="aleppo",
                occupation_category="journalist",
                political_activity_category="media_activism",
                file_classification="draft", documenter=admin,
            )
            DetentionEvent.objects.create(
                survivor=s2, detention_date=date(2017, 6, 1),
                detention_location="منزلها في حلب",
                arresting_entity="المخابرات الجوية - فرع التحقيق",
                circumstances="اقتُحم المنزل ليلاً.",
            )
            self.stdout.write(self.style.SUCCESS(f"✓ ملف تجريبي جزئي: {s2}"))

        # ============================================================
        # سيناريو 3: ملف مسودة (فارغ - للتدرّب من الصفر)
        # ============================================================
        if not SurvivorProfile.all_objects.filter(case_reference="TRN-2026-C001").exists():
            s3 = SurvivorProfile.objects.create(
                case_reference="TRN-2026-C001",
                first_name="فادي", father_name="جورج",
                family_name="التجريبي", gender="male",
                file_classification="draft", documenter=admin,
            )
            SurvivorNote.objects.create(
                survivor=s3, author=admin,
                note_type="general",
                title="ملف للتدريب",
                content="هذا ملف فارغ تقريباً - ادخل عليه وأضف البيانات لتتدرّب على عملية التوثيق من البداية للنهاية.",
                is_pinned=True,
            )
            self.stdout.write(self.style.SUCCESS(f"✓ ملف تجريبي مسودة: {s3}"))

        self.stdout.write(self.style.SUCCESS(
            "\n✨ تم بذر 3 ملفات تدريبية. ابدأ بـ TRN-2026-C001 لتجربة التوثيق من الصفر."
        ))
