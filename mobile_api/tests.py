"""اختبار شامل لمزامنة الحزمة الكاملة من الجوال إلى السيرفر."""

import json

from django.test import Client, TestCase

from accounts.models import User
from survivors.models import SurvivorProfile

from .models import AuthToken


class FullBundleSyncTest(TestCase):
    def setUp(self):
        self.user = User.objects.create_user(
            username="vol", password="x", role=User.Role.DOCUMENTER,
        )
        self.token = AuthToken.generate(self.user, device_name="test")
        self.client = Client()

    def _bundle(self):
        return {
            "_local_id": 7,
            "case_reference": "HQ-TEST-0001",
            "first_name": "أحمد",
            "father_name": "محمد",
            "family_name": "السوري",
            "gender": "male",
            "nationality": "سورية",
            "file_classification": "draft",
            "birth_date": "1990-05-01",
            "consent": {
                "consent_documented": True,
                "withdrawal_right_explained": True,
                "confidentiality_limits_explained": True,
                "intended_uses_explained": True,
                "share_with_iiim": True,
            },
            "release_event": {
                "release_date": "2015-01-10",
                "release_type": "amnesty",
                "circumstances": "أُفرج عنه بعفو عام",
            },
            "long_term_impact": {
                "sleep_disorders": True,
                "flashbacks": True,
                "psychological_symptoms": "قلق دائم",
            },
            "detention_events": [
                {
                    "detention_date": "2013-03-15",
                    "detention_location": "حاجز في حلب",
                    "arresting_entity": "المخابرات الجوية",
                    "circumstances": "اعتُقل على حاجز أثناء عودته من العمل.",
                    "governorate": "aleppo",
                },
            ],
            "detention_periods": [
                {
                    "facility_name": "فرع فلسطين - الفرع 235",
                    "from_date": "2013-03-15",
                    "to_date": "2014-06-01",
                    "torture_description": "تعرّض للضرب المبرح والتعليق.",
                    "sexual_violence_reported": False,
                    "torture_methods": [
                        "الضرب بالكابلات والعصي",
                        "الشبح (التعليق من اليدين)",
                    ],
                },
            ],
            "witnesses": [
                {
                    "witness_name": "خالد",
                    "facility_name": "فرع فلسطين - الفرع 235",
                    "period_from": "2013-04-01",
                    "how_recognized": "كانا في نفس الزنزانة.",
                    "full_testimony": "شهد على وجوده واحتجازه.",
                    "is_independent": True,
                    "consent_to_use_testimony": True,
                },
            ],
            "documents": [
                {
                    "document_type": "release_order",
                    "title": "أمر إفراج",
                    "description": "نسخة من أمر الإفراج.",
                    "source_description": "سلّمته العائلة.",
                    "date_obtained": "2015-02-01",
                },
            ],
            "medical_assessments": [
                {
                    "assessment_type": "comprehensive",
                    "assessment_date": "2016-01-01",
                    "assessor_name": "د. ليلى",
                    "assessor_credentials": "طبيبة شرعية",
                    "istanbul_protocol_compliant": True,
                    "consistency_with_account": "highly_consistent",
                },
            ],
            "interviews": [
                {
                    "sequence_number": 1,
                    "is_first": True,
                    "interview_date": "2016-02-01",
                    "methodology": "istanbul",
                    "language": "ar_levantine",
                    "recorded": True,
                },
            ],
            "notes": [
                {"note_type": "follow_up", "content": "يحتاج متابعة نفسية."},
            ],
            "household_survey": {
                "marital_status": "married",
                "survey_date": "2016-03-01",
                "household_size": 5,
            },
            "children": [
                {"name": "سارة", "gender": "female", "age": 8,
                 "current_stage": "primary"},
                {"name": "عمر", "gender": "male", "age": 12,
                 "dropped_out": True},
            ],
            "housing": {
                "housing_type": "rented",
                "rent_amount": 150.0,
                "rent_currency": "USD",
                "rooms_count": 2,
            },
            "education": {
                "highest_level_before_detention": "secondary",
                "highest_level_now": "secondary",
            },
            "employment": {
                "status": "daily_labor",
                "monthly_income": 100.0,
            },
            "health_access": {
                "food_security": "poor",
                "meals_per_day": 2,
            },
            "needs": {
                "assessment_date": "2016-03-01",
                "financial_aid_priority": "critical",
                "needs_id_card": True,
            },
        }

    def _post(self):
        return self.client.post(
            "/api/v1/sync/push/",
            data=json.dumps({"survivors": [self._bundle()],
                             "device_id": "test"}),
            content_type="application/json",
            HTTP_AUTHORIZATION=f"Token {self.token.key}",
        )

    def test_full_bundle_persists(self):
        resp = self._post()
        self.assertEqual(resp.status_code, 200, resp.content)
        body = resp.json()
        self.assertEqual(body["success"], 1, body)
        self.assertTrue(body["results"][0]["ok"], body["results"])

        s = SurvivorProfile.objects.get(case_reference="HQ-TEST-0001")
        self.assertEqual(s.first_name, "أحمد")
        self.assertTrue(s.consent.consent_documented)
        self.assertTrue(s.consent.is_fully_compliant)
        self.assertEqual(s.release_event.release_type, "amnesty")
        self.assertTrue(s.long_term_impact.sleep_disorders)
        self.assertEqual(s.detention_events.count(), 1)

        period = s.detention_periods.get()
        self.assertEqual(period.facility.name_ar, "فرع فلسطين - الفرع 235")
        self.assertEqual(period.torture_methods.count(), 2)

        w = s.witnesses.get()
        self.assertTrue(w.is_independent)
        self.assertEqual(w.facility_witnessed_at.name_ar,
                         "فرع فلسطين - الفرع 235")

        self.assertEqual(s.documents.count(), 1)
        self.assertTrue(
            s.medical_assessments.get().istanbul_protocol_compliant)
        self.assertEqual(s.interviews.get().sequence_number, 1)
        self.assertEqual(s.notes.get().note_type, "follow_up")

        hh = s.household_survey
        self.assertEqual(hh.marital_status, "married")
        self.assertEqual(hh.children.count(), 2)
        self.assertEqual(hh.housing.housing_type, "rented")
        self.assertEqual(hh.health_access.food_security, "poor")
        self.assertEqual(hh.needs.financial_aid_priority, "critical")
        self.assertEqual(s.education.highest_level_now, "secondary")
        self.assertEqual(s.employment.status, "daily_labor")

        # التحقق المتقاطع يرتفع (شاهد مستقل + وثيقة رسمية + طبي إسطنبول)
        s.recompute_scores(save=False)
        self.assertGreaterEqual(s.corroboration_score, 3)

    def test_idempotent_resync(self):
        """إعادة المزامنة لا تُكرّر السجلات المتعددة."""
        self.assertEqual(self._post().status_code, 200)
        self.assertEqual(self._post().status_code, 200)
        s = SurvivorProfile.objects.get(case_reference="HQ-TEST-0001")
        self.assertEqual(s.detention_periods.count(), 1)
        self.assertEqual(s.household_survey.children.count(), 2)
        self.assertEqual(
            SurvivorProfile.objects.filter(
                case_reference="HQ-TEST-0001").count(), 1)
