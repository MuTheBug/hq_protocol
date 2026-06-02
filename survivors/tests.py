"""اختبارات لتوليد رقم القضية الفريد."""

import re
from datetime import date

from django.test import TestCase

from .models import SurvivorProfile, generate_case_reference


class CaseReferenceGenerationTest(TestCase):
    def test_format(self):
        ref = generate_case_reference()
        self.assertRegex(ref, r"^HQ-\d{4}-[0-9A-F]{6}$")
        self.assertIn(str(date.today().year), ref)

    def test_uniqueness_under_pressure(self):
        # توليد 500 رقم — يجب أن تكون كلها فريدة
        refs = {generate_case_reference() for _ in range(500)}
        self.assertEqual(len(refs), 500)

    def test_avoids_existing(self):
        # نُنشئ ملفاً برقم محدد، ثم نحرص ألا تتولد قيمة مكرَّرة
        used = "HQ-2026-AAAAAA"
        SurvivorProfile.objects.create(
            case_reference=used,
            first_name="ت", father_name="ت", family_name="ت", gender="male",
        )
        for _ in range(20):
            self.assertNotEqual(generate_case_reference(), used)
