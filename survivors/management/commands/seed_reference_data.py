"""بذر البيانات المرجعية: مراكز الاحتجاز الموثّقة وأنماط التعذيب."""

from django.core.management.base import BaseCommand

from survivors.models import DetentionFacility, TortureMethod


FACILITIES = [
    # المخابرات العسكرية
    ("فرع التحقيق العسكري - فرع 248", "248", "military_intel", "دمشق", "الميسات، دمشق"),
    ("فرع المنطقة - فرع 227", "227", "military_intel", "دمشق", "دمشق"),
    ("فرع فلسطين - فرع 235", "235", "military_intel", "دمشق", "دمشق"),
    ("فرع المخابرات العسكرية - حلب", "", "military_intel", "حلب", "حلب"),
    ("فرع المخابرات العسكرية - حمص", "", "military_intel", "حمص", "حمص"),
    ("فرع المخابرات العسكرية - دير الزور", "", "military_intel", "دير الزور", "دير الزور"),
    # المخابرات الجوية
    ("فرع المخابرات الجوية - المطار", "", "air_force_intel", "دمشق", "مطار المزة، دمشق"),
    ("فرع المخابرات الجوية - حرستا", "", "air_force_intel", "ريف دمشق", "حرستا"),
    ("فرع التحقيق - المخابرات الجوية", "", "air_force_intel", "دمشق", "دمشق"),
    # أمن الدولة (المخابرات العامة)
    ("فرع التحقيق - أمن الدولة - فرع 285", "285", "general_intel", "دمشق", "كفرسوسة، دمشق"),
    ("فرع المنطقة - أمن الدولة - فرع 251 (الخطيب)", "251", "general_intel", "دمشق", "الخطيب، دمشق"),
    ("فرع الداخلية - أمن الدولة - فرع 255", "255", "general_intel", "دمشق", "دمشق"),
    ("فرع أمن الدولة - حلب", "", "general_intel", "حلب", "حلب"),
    ("فرع أمن الدولة - حمص", "", "general_intel", "حمص", "حمص"),
    # الأمن السياسي
    ("فرع الأمن السياسي - دمشق", "", "political_sec", "دمشق", "دمشق"),
    ("فرع الأمن السياسي - حلب", "", "political_sec", "حلب", "حلب"),
    ("فرع الأمن السياسي - حمص", "", "political_sec", "حمص", "حمص"),
    # السجون المركزية
    ("سجن صيدنايا العسكري", "", "prisons_dept", "ريف دمشق", "صيدنايا"),
    ("سجن عدرا المركزي", "", "prisons_dept", "ريف دمشق", "عدرا"),
    ("سجن دمشق المركزي", "", "prisons_dept", "دمشق", "دمشق"),
    ("سجن حلب المركزي", "", "prisons_dept", "حلب", "حلب"),
    ("سجن حمص المركزي", "", "prisons_dept", "حمص", "حمص"),
    ("سجن دير الزور المركزي", "", "prisons_dept", "دير الزور", "دير الزور"),
    ("سجن حماة المركزي", "", "prisons_dept", "حماة", "حماة"),
    ("سجن اللاذقية المركزي", "", "prisons_dept", "اللاذقية", "اللاذقية"),
    # الشرطة العسكرية
    ("مشفى تشرين العسكري - الشرطة العسكرية", "", "military_police", "دمشق", "دمشق"),
    ("مشفى المزة العسكري - الشرطة العسكرية (601)", "601", "military_police", "دمشق", "دمشق"),
]


TORTURE_METHODS = [
    # جسدي
    ("الضرب بالكابلات والعصي", "physical", "Beating with cables and sticks"),
    ("الفلقة (ضرب أسفل القدمين)", "physical", "Falaka - beating soles of the feet"),
    ("الشبح (التعليق من اليدين)", "physical", "Hanging by hands (Shabh)"),
    ("الدولاب", "physical", "Tire torture (Dulab)"),
    ("الكرسي الألماني", "physical", "German chair"),
    ("الصعق الكهربائي", "physical", "Electric shock"),
    ("حرق بالسجائر", "physical", "Cigarette burns"),
    ("الإغراق الوهمي", "physical", "Waterboarding"),
    ("خلع الأظافر/الأسنان", "physical", "Pulling nails/teeth"),
    ("كسر العظام", "physical", "Breaking bones"),
    ("بساط الريح", "physical", "Flying carpet (Bisat Al-Rih)"),
    # نفسي
    ("التهديد بإيذاء الأهل", "psychological", "Threats to harm family"),
    ("التهديد بالإعدام (الإعدام الوهمي)", "psychological", "Mock execution"),
    ("الحبس الانفرادي المطوّل", "psychological", "Prolonged solitary confinement"),
    ("إجبار على مشاهدة تعذيب آخرين", "psychological", "Forced to witness torture"),
    ("إجبار على تكرار شعارات", "psychological", "Forced to chant slogans"),
    ("الإهانات والشتائم", "psychological", "Insults and degradation"),
    ("التهديد بالاغتصاب", "psychological", "Threats of sexual violence"),
    # جنسي
    ("التحرش/الاعتداء الجنسي", "sexual", "Sexual assault"),
    ("الاغتصاب", "sexual", "Rape"),
    ("التعرية القسرية", "sexual", "Forced nudity"),
    ("التفتيش العاري", "sexual", "Strip searches"),
    # بيئي
    ("الاكتظاظ الشديد", "environmental", "Severe overcrowding"),
    ("الحرارة/البرودة الشديدة", "environmental", "Extreme heat/cold"),
    ("الحرمان من التهوية", "environmental", "Deprivation of ventilation"),
    ("الإضاءة المستمرة أو الظلام الدائم", "environmental", "Permanent light or darkness"),
    ("الضوضاء العالية المستمرة", "environmental", "Loud continuous noise"),
    # حرمان
    ("الحرمان من الطعام", "deprivation", "Food deprivation"),
    ("الحرمان من الماء", "deprivation", "Water deprivation"),
    ("الحرمان من النوم", "deprivation", "Sleep deprivation"),
    ("الحرمان من العلاج", "deprivation", "Denial of medical care"),
    ("الحرمان من استخدام المرحاض", "deprivation", "Denial of bathroom use"),
    ("الحرمان من النظافة", "deprivation", "Denial of hygiene"),
]


class Command(BaseCommand):
    help = "بذر البيانات المرجعية: مراكز الاحتجاز وأنماط التعذيب"

    def handle(self, *args, **options):
        created_f = 0
        for name, branch, entity, gov, addr in FACILITIES:
            obj, created = DetentionFacility.objects.get_or_create(
                name_ar=name,
                defaults={
                    "branch_number": branch,
                    "parent_entity": entity,
                    "governorate": gov,
                    "address": addr,
                },
            )
            if created:
                created_f += 1
        self.stdout.write(self.style.SUCCESS(
            f"✓ {created_f} مركز احتجاز جديد ({DetentionFacility.objects.count()} إجمالي)"
        ))

        created_t = 0
        for name_ar, category, name_en in TORTURE_METHODS:
            obj, created = TortureMethod.objects.get_or_create(
                name_ar=name_ar,
                defaults={"category": category, "name_en": name_en},
            )
            if created:
                created_t += 1
        self.stdout.write(self.style.SUCCESS(
            f"✓ {created_t} نمط تعذيب جديد ({TortureMethod.objects.count()} إجمالي)"
        ))
