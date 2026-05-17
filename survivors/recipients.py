"""
الجهات الخارجية المعتمدة لاستلام ملفات الناجين.

كل جهة لها متطلبات موافقة محددة (يتم التحقق منها قبل التصدير)
وعنوان مراسلة رسمي يُدرج في خطاب الإحالة.
"""


RECIPIENTS = {
    "iiim": {
        "code": "iiim",
        "name_ar": "الآلية الدولية المحايدة المستقلة لسوريا",
        "name_en": "International, Impartial and Independent Mechanism (IIIM)",
        "address": "Palais des Nations, 1211 Geneva 10, Switzerland",
        "address_ar": "قصر الأمم، 1211 جنيف 10، سويسرا",
        "website": "https://iiim.un.org",
        "email": "iiim-info-providers@un.org",
        "focal_point": "Information Provider Coordinator",
        "requires_consent": "share_with_iiim",
        "notes": "تُسلَّم الملفات عبر بوابة IIIM الآمنة بعد توقيع Information Provider Agreement.",
    },
    "coi": {
        "code": "coi",
        "name_ar": "لجنة التحقيق الدولية المستقلة المعنية بسوريا",
        "name_en": "UN Independent International Commission of Inquiry on the Syrian Arab Republic",
        "address": "OHCHR - Palais des Nations, 1211 Geneva 10, Switzerland",
        "address_ar": "مفوضية حقوق الإنسان، قصر الأمم، جنيف، سويسرا",
        "website": "https://www.ohchr.org/en/hr-bodies/hrc/iici-syria",
        "email": "coi-syria@un.org",
        "focal_point": "Commission Secretariat",
        "requires_consent": "share_with_coi",
        "notes": "تنشر تقارير دورية لمجلس حقوق الإنسان. تستقبل المعلومات من مصادر مفتوحة وسرية.",
    },
    "icc": {
        "code": "icc",
        "name_ar": "المحكمة الجنائية الدولية",
        "name_en": "International Criminal Court (ICC)",
        "address": "Oude Waalsdorperweg 10, 2597 AK The Hague, Netherlands",
        "address_ar": "لاهاي، هولندا",
        "website": "https://www.icc-cpi.int",
        "email": "OTP.InformationDesk@icc-cpi.int",
        "focal_point": "Office of the Prosecutor - Information Desk",
        "requires_consent": "share_with_icc",
        "notes": "تستقبل البلاغات عبر مكتب المدّعي العام. غير سوريا عضواً ولكن قد تنظر تحت سلطة قضائية لدول أعضاء.",
    },
    "syria_tj": {
        "code": "syria_tj",
        "name_ar": "هيئة العدالة الانتقالية في سوريا",
        "name_en": "Syrian Transitional Justice Authority",
        "address": "دمشق - الجمهورية العربية السورية",
        "address_ar": "دمشق، سوريا",
        "focal_point": "الإدارة العامة - قسم المعتقلين والمختفين قسرياً",
        "requires_consent": None,
        "notes": "الجهة الوطنية المعنية بالعدالة الانتقالية ومسار المساءلة الداخلية.",
    },
    "german_prosecutor": {
        "code": "german_prosecutor",
        "name_ar": "النائب العام الاتحادي الألماني - وحدة جرائم الحرب",
        "name_en": "German Federal Public Prosecutor (Generalbundesanwalt) - War Crimes Unit",
        "address": "Brauerstraße 30, 76135 Karlsruhe, Germany",
        "address_ar": "كارلسروه، ألمانيا",
        "website": "https://www.generalbundesanwalt.de",
        "focal_point": "Zentralstelle für die Bekämpfung von Kriegsverbrechen (ZBKV)",
        "requires_consent": "share_with_universal_jurisdiction",
        "notes": "الجهة التي تابعت قضايا كوبلنز وفرانكفورت (أنور رسلان، علاء موسى، إلخ).",
    },
    "french_prosecutor": {
        "code": "french_prosecutor",
        "name_ar": "النيابة العامة الفرنسية لمكافحة الإرهاب والجرائم ضد الإنسانية",
        "name_en": "French National Anti-Terror Prosecution Office (PNAT)",
        "address": "Tribunal de Paris, 75017 Paris, France",
        "address_ar": "باريس، فرنسا",
        "focal_point": "Pôle Crimes contre l'Humanité",
        "requires_consent": "share_with_universal_jurisdiction",
        "notes": "تابعت قضية المخابرات السورية وأصدرت مذكرات اعتقال ضد مسؤولين سوريين.",
    },
    "swedish_prosecutor": {
        "code": "swedish_prosecutor",
        "name_ar": "النيابة العامة السويدية - وحدة جرائم الحرب",
        "name_en": "Swedish Prosecution Authority - War Crimes & Crimes Against International Law Unit",
        "address": "Östermalmsgatan 87C, 114 59 Stockholm, Sweden",
        "address_ar": "ستوكهولم، السويد",
        "website": "https://www.aklagare.se",
        "focal_point": "International Public Prosecution Office",
        "requires_consent": "share_with_universal_jurisdiction",
        "notes": "تابعت قضايا في ستوكهولم منذ 2015 (محمد عبد الله، حيدر سعيد، إلخ).",
    },
    "dutch_prosecutor": {
        "code": "dutch_prosecutor",
        "name_ar": "النيابة العامة الهولندية - فريق الجرائم الدولية",
        "name_en": "Dutch Public Prosecution Service - International Crimes Team",
        "address": "Den Haag, Netherlands",
        "address_ar": "لاهاي، هولندا",
        "focal_point": "Landelijk Parket - Team Internationale Misdrijven",
        "requires_consent": "share_with_universal_jurisdiction",
        "notes": "تتعاون مع الـIIIM وتستلم بلاغات الولاية القضائية العالمية.",
    },
    "us_ait": {
        "code": "us_ait",
        "name_ar": "وحدة العدالة الجنائية الدولية - وزارة العدل الأميركية",
        "name_en": "US Department of Justice - Human Rights and Special Prosecutions Section",
        "address": "Washington, DC, USA",
        "focal_point": "HRSP - Atrocities Crime Reward Program",
        "requires_consent": "share_with_universal_jurisdiction",
        "notes": "وزارة العدل الأميركية تستلم بلاغات تحت قانون Magnitsky وقوانين أخرى.",
    },
    "cija": {
        "code": "cija",
        "name_ar": "لجنة العدالة والمساءلة الدولية",
        "name_en": "Commission for International Justice and Accountability (CIJA)",
        "website": "https://cijaonline.org",
        "focal_point": "Syria Programme",
        "requires_consent": "share_with_partner_orgs",
        "notes": "أكبر أرشيف وثائق نظام سوري؛ تُعد ملفات قضائية للمحاكم الأوروبية.",
    },
    "snhr": {
        "code": "snhr",
        "name_ar": "الشبكة السورية لحقوق الإنسان",
        "name_en": "Syrian Network for Human Rights (SNHR)",
        "website": "https://snhr.org",
        "focal_point": "قسم المعتقلين والمختفين قسرياً",
        "requires_consent": "share_with_partner_orgs",
        "notes": "أكبر قاعدة بيانات مفتوحة المصدر لضحايا الانتهاكات في سوريا.",
    },
    "sjac": {
        "code": "sjac",
        "name_ar": "مركز العدالة السوري (SJAC)",
        "name_en": "Syria Justice and Accountability Centre (SJAC)",
        "website": "https://syriaaccountability.org",
        "focal_point": "Bayanat Database Team",
        "requires_consent": "share_with_partner_orgs",
        "notes": "يدير قاعدة بيانات Bayanat ويوفّر تدريبات للمنظمات السورية.",
    },
    "ldhr": {
        "code": "ldhr",
        "name_ar": "أطباء ومحامون لحقوق الإنسان",
        "name_en": "Lawyers and Doctors for Human Rights (LDHR)",
        "focal_point": "قسم التقييم الطبي وفق بروتوكول إسطنبول",
        "requires_consent": "share_with_partner_orgs",
        "notes": "متخصصون بالتقييم الطبي الشرعي للناجين وفق بروتوكول إسطنبول.",
    },
    "admsp": {
        "code": "admsp",
        "name_ar": "رابطة معتقلي ومفقودي سجن صيدنايا (ADMSP)",
        "name_en": "Association of Detainees and Missing Persons of Saydnaya Prison (ADMSP)",
        "focal_point": "قسم التوثيق",
        "requires_consent": "share_with_partner_orgs",
        "notes": "تخصص في توثيق ناجي سجن صيدنايا والمعتقلات الأخرى.",
    },
    "caesar_families": {
        "code": "caesar_families",
        "name_ar": "رابطة عائلات قيصر",
        "name_en": "Caesar Families Association",
        "focal_point": "قسم التوثيق والمناصرة",
        "requires_consent": "share_with_partner_orgs",
        "notes": "تجمع عائلات ضحايا تسريبات قيصر؛ منصة دولية للمناصرة.",
    },
}


def get_recipient(code):
    return RECIPIENTS.get(code)


def all_recipients_by_category():
    """يصنّف المستلمين لعرضهم في الواجهة."""
    categories = {
        "أممية": ["iiim", "coi", "icc"],
        "وطنية سورية": ["syria_tj"],
        "ولاية قضائية عالمية": [
            "german_prosecutor", "french_prosecutor",
            "swedish_prosecutor", "dutch_prosecutor", "us_ait",
        ],
        "منظمات شريكة": [
            "cija", "snhr", "sjac", "ldhr", "admsp", "caesar_families",
        ],
    }
    return {
        cat: [RECIPIENTS[code] for code in codes if code in RECIPIENTS]
        for cat, codes in categories.items()
    }
