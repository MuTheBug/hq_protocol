import 'field_spec.dart';

/// البيانات المرجعية المضمَّنة في التطبيق (تعمل دون اتصال بالكامل).
///
/// كل القوائم منسوخة حرفياً من النظام المركزي (Django) لضمان توافق
/// القيم المخزَّنة مع السيرفر عند المزامنة.
class Ref {
  Ref._();

  static String labelFor(List<Choice> choices, String? value) {
    if (value == null || value.isEmpty) return '';
    for (final c in choices) {
      if (c.value == value) return c.label;
    }
    return value;
  }

  // ---- المحافظات السورية (14) ----
  static const governorates = <Choice>[
    Choice('damascus', 'دمشق'),
    Choice('rural_damascus', 'ريف دمشق'),
    Choice('aleppo', 'حلب'),
    Choice('homs', 'حمص'),
    Choice('hama', 'حماة'),
    Choice('latakia', 'اللاذقية'),
    Choice('tartus', 'طرطوس'),
    Choice('idlib', 'إدلب'),
    Choice('daraa', 'درعا'),
    Choice('suwayda', 'السويداء'),
    Choice('quneitra', 'القنيطرة'),
    Choice('raqqa', 'الرقة'),
    Choice('deir_ez_zor', 'دير الزور'),
    Choice('hasakah', 'الحسكة'),
  ];

  // ---- البلدان ----
  static const countries = <Choice>[
    Choice('SY', 'سوريا'),
    Choice('TR', 'تركيا'),
    Choice('LB', 'لبنان'),
    Choice('JO', 'الأردن'),
    Choice('IQ', 'العراق'),
    Choice('EG', 'مصر'),
    Choice('DE', 'ألمانيا'),
    Choice('NL', 'هولندا'),
    Choice('SE', 'السويد'),
    Choice('FR', 'فرنسا'),
    Choice('GB', 'بريطانيا'),
    Choice('AT', 'النمسا'),
    Choice('BE', 'بلجيكا'),
    Choice('DK', 'الدنمارك'),
    Choice('NO', 'النرويج'),
    Choice('US', 'الولايات المتحدة'),
    Choice('CA', 'كندا'),
    Choice('SA', 'السعودية'),
    Choice('AE', 'الإمارات'),
    Choice('QA', 'قطر'),
    Choice('KW', 'الكويت'),
    Choice('OTHER', 'أخرى'),
  ];

  // ---- فئات المهنة ----
  static const occupations = <Choice>[
    Choice('student_school', 'طالب مدرسي'),
    Choice('student_university', 'طالب جامعي'),
    Choice('teacher', 'معلم/أستاذ'),
    Choice('doctor', 'طبيب'),
    Choice('nurse', 'ممرض/ة'),
    Choice('lawyer', 'محامي'),
    Choice('engineer', 'مهندس'),
    Choice('journalist', 'صحفي/إعلامي'),
    Choice('activist', 'ناشط حقوقي/إنساني'),
    Choice('civil_servant', 'موظف حكومي'),
    Choice('military', 'عسكري/أمني'),
    Choice('merchant', 'تاجر/صاحب عمل'),
    Choice('worker', 'عامل'),
    Choice('farmer', 'مزارع'),
    Choice('driver', 'سائق'),
    Choice('housewife', 'ربّة منزل'),
    Choice('religious', 'رجل دين/إمام'),
    Choice('artist', 'فنان/مبدع'),
    Choice('unemployed', 'بدون عمل'),
    Choice('retired', 'متقاعد'),
    Choice('other', 'أخرى'),
  ];

  // ---- النشاط السياسي ----
  static const politicalActivities = <Choice>[
    Choice('peaceful_protest', 'نشاط احتجاجي سلمي'),
    Choice('media_activism', 'نشاط إعلامي/توثيقي'),
    Choice('humanitarian', 'عمل إنساني/إغاثي'),
    Choice('medical_aid', 'إسعاف/علاج للجرحى'),
    Choice('political_party', 'منتسب لحزب سياسي معارض'),
    Choice('armed_group_fsa', 'الجيش الحر'),
    Choice('armed_group_other', 'فصيل مسلح آخر'),
    Choice('civil_society', 'منظمة مجتمع مدني'),
    Choice('religious_oppose', 'معارضة على خلفية دينية'),
    Choice('kurdish_political', 'نشاط سياسي كردي'),
    Choice('no_activity', 'لا نشاط سياسي - اعتقال عشوائي'),
    Choice('relative_of', 'بسبب قرابة لشخص آخر'),
    Choice('unknown_reason', 'السبب غير معلوم'),
    Choice('other', 'أخرى'),
  ];

  // ---- الحالة الزوجية (وقت الاعتقال) ----
  static const maritalStatuses = <Choice>[
    Choice('single', 'أعزب/عزباء'),
    Choice('engaged', 'مخطوب/ة'),
    Choice('married', 'متزوج/ة'),
    Choice('divorced', 'مطلّق/ة'),
    Choice('widowed', 'أرمل/أرملة'),
    Choice('separated', 'منفصل/ة'),
  ];

  // ---- لغات المقابلة ----
  static const interviewLanguages = <Choice>[
    Choice('ar', 'العربية - الفصحى'),
    Choice('ar_levantine', 'العربية - الشامية'),
    Choice('ku', 'الكردية'),
    Choice('en', 'الإنجليزية'),
    Choice('tr', 'التركية'),
    Choice('de', 'الألمانية'),
    Choice('fr', 'الفرنسية'),
    Choice('other', 'أخرى'),
  ];

  // ---- الجنس ----
  static const genders = <Choice>[
    Choice('male', 'ذكر'),
    Choice('female', 'أنثى'),
    Choice('other', 'آخر/لا يصرّح'),
  ];

  // ---- تصنيف الملف ----
  static const fileClassifications = <Choice>[
    Choice('draft', 'مسودة - قيد الجمع'),
    Choice('A', 'فئة A - جاهز للمحاكم الدولية'),
    Choice('B', 'فئة B - جاهز للـIIIM ولجنة التحقيق'),
    Choice('C', 'فئة C - أرشيف/إحصاء فقط'),
  ];

  // ---- نوع الإفراج ----
  static const releaseTypes = <Choice>[
    Choice('unconditional', 'إفراج غير مشروط'),
    Choice('conditional', 'إفراج مشروط'),
    Choice('amnesty', 'عفو عام'),
    Choice('settlement', 'تسوية وضع'),
    Choice('bribe', 'بدفع رشوة'),
    Choice('exchange', 'تبادل/صفقة'),
    Choice('escape', 'فرار'),
    Choice('transfer_out', 'نقل لجهة أخرى'),
    Choice('unknown', 'غير معلوم'),
  ];

  // ---- علاقة الشاهد قبل الاعتقال ----
  static const witnessRelationships = <Choice>[
    Choice('stranger', 'لم يكن يعرفه'),
    Choice('acquaintance', 'معرفة'),
    Choice('friend', 'صديق'),
    Choice('relative', 'قريب'),
    Choice('colleague', 'زميل عمل/دراسة'),
  ];

  // ---- نوع الوثيقة ----
  static const documentTypes = <Choice>[
    Choice('official_regime', 'وثيقة رسمية من جهة سورية'),
    Choice('court_document', 'وثيقة قضائية (محكمة عسكرية/ميدانية)'),
    Choice('arrest_warrant', 'أمر اعتقال'),
    Choice('release_order', 'أمر إفراج'),
    Choice('transfer_order', 'أمر إحالة/نقل'),
    Choice('international_court', 'وثيقة من محكمة دولية/IIIM'),
    Choice('leaked', 'وثيقة مسرّبة (قيصر، تسريبات الفروع...)'),
    Choice('family_visit', 'كرت زيارة/إيصال زيارة'),
    Choice('family_remittance', 'حوالة مالية للسجن'),
    Choice('lawyer', 'وثيقة من محامٍ'),
    Choice('media', 'مادة إعلامية'),
    Choice('social_media', 'منشور وسائل تواصل'),
    Choice('photo', 'صورة فوتوغرافية'),
    Choice('video', 'فيديو'),
    Choice('audio', 'تسجيل صوتي'),
    Choice('other', 'أخرى'),
  ];

  // ---- نوع التقييم الطبي ----
  static const assessmentTypes = <Choice>[
    Choice('physical', 'جسدي'),
    Choice('psychological', 'نفسي'),
    Choice('comprehensive', 'شامل'),
  ];

  // ---- مدى التوافق (إسطنبول) ----
  static const consistencyLevels = <Choice>[
    Choice('not_assessed', 'لم يُقَيَّم'),
    Choice('not_consistent', 'غير متوافق'),
    Choice('consistent', 'متوافق'),
    Choice('highly_consistent', 'متوافق بدرجة عالية'),
    Choice('typical', 'نمطي/مطابق تماماً'),
    Choice('diagnostic', 'تشخيصي - دليل قاطع'),
  ];

  // ---- منهجية المقابلة ----
  static const interviewMethodologies = <Choice>[
    Choice('istanbul', 'بروتوكول إسطنبول'),
    Choice('semi_structured', 'شبه منظمة'),
    Choice('narrative', 'سردية مفتوحة'),
    Choice('structured', 'استمارة منظمة'),
    Choice('follow_up', 'مقابلة متابعة'),
    Choice('other', 'أخرى'),
  ];

  // ---- مكان المقابلة ----
  static const interviewLocations = <Choice>[
    Choice('office', 'في مكاتب الجمعية'),
    Choice('survivor_home', 'في منزل الناجي'),
    Choice('remote', 'عن بُعد (Zoom/Skype...)'),
    Choice('phone', 'هاتفية'),
    Choice('field', 'ميدانية أخرى'),
    Choice('other', 'أخرى'),
  ];

  // ---- نوع الملاحظة ----
  static const noteTypes = <Choice>[
    Choice('general', 'ملاحظة عامة'),
    Choice('follow_up', 'متابعة'),
    Choice('referral', 'إحالة'),
    Choice('medical', 'طبية/نفسية'),
    Choice('legal', 'قانونية'),
    Choice('security', 'أمنية/حماية'),
    Choice('family', 'متعلقة بالعائلة'),
    Choice('inconsistency', 'ملاحظة على اتساق الرواية'),
    Choice('verification', 'تحقق من معلومة'),
    Choice('other', 'أخرى'),
  ];

  // ============ المسح الاجتماعي ============

  static const householdMaritalStatuses = <Choice>[
    Choice('single', 'أعزب/عزباء'),
    Choice('married', 'متزوج/ة'),
    Choice('divorced', 'مطلّق/ة'),
    Choice('widowed', 'أرمل/أرملة'),
    Choice('separated', 'منفصل/ة'),
    Choice('engaged', 'مخطوب/ة'),
  ];

  static const displacementStatuses = <Choice>[
    Choice('not_displaced', 'لم يُهجَّر'),
    Choice('idp', 'نازح داخلياً'),
    Choice('refugee', 'لاجئ خارج سوريا'),
    Choice('returnee', 'عائد بعد لجوء'),
    Choice('asylum_seeker', 'طالب لجوء'),
  ];

  static const childGenders = <Choice>[
    Choice('male', 'ذكر'),
    Choice('female', 'أنثى'),
  ];

  static const schoolStages = <Choice>[
    Choice('preschool', 'روضة'),
    Choice('primary', 'ابتدائي'),
    Choice('preparatory', 'إعدادي'),
    Choice('secondary', 'ثانوي'),
    Choice('vocational', 'مهني/تقني'),
    Choice('university', 'جامعي'),
    Choice('postgraduate', 'دراسات عليا'),
    Choice('not_started', 'لم يبدأ الدراسة بعد'),
    Choice('never_attended', 'لم يلتحق بالمدرسة قطّ'),
  ];

  static const childWorkTypes = <Choice>[
    Choice('student', 'طالب فقط'),
    Choice('helps_family', 'يساعد الأسرة'),
    Choice('child_labor', 'عمالة أطفال'),
    Choice('street_work', 'عمل في الشارع'),
    Choice('apprentice', 'متدرّب/صبي مهنة'),
    Choice('regular_job', 'عمل منتظم'),
    Choice('none', 'لا يعمل'),
  ];

  static const housingTypes = <Choice>[
    Choice('owned', 'ملك خاص'),
    Choice('rented', 'إيجار'),
    Choice('with_family', 'مع أهل/أقارب'),
    Choice('shared', 'سكن مشترك'),
    Choice('idp_camp', 'مخيم نازحين'),
    Choice('refugee_camp', 'مخيم لاجئين'),
    Choice('shelter', 'مأوى/مركز إيواء'),
    Choice('damaged', 'منزل متضرر'),
    Choice('destroyed', 'المنزل الأصلي مدمَّر'),
    Choice('homeless', 'بلا مأوى'),
    Choice('other', 'أخرى'),
  ];

  static const housingConditions = <Choice>[
    Choice('good', 'جيدة'),
    Choice('acceptable', 'مقبولة'),
    Choice('poor', 'سيئة'),
    Choice('very_poor', 'سيئة جداً/غير صالحة للسكن'),
  ];

  static const currencies = <Choice>[
    Choice('SYP', 'ليرة سورية'),
    Choice('USD', 'دولار أميركي'),
    Choice('TRY', 'ليرة تركية'),
    Choice('EUR', 'يورو'),
    Choice('other', 'أخرى'),
  ];

  static const educationLevels = <Choice>[
    Choice('illiterate', 'أمي'),
    Choice('reads_writes', 'يقرأ ويكتب فقط'),
    Choice('primary', 'ابتدائي'),
    Choice('preparatory', 'إعدادي'),
    Choice('secondary', 'ثانوي/بكالوريا'),
    Choice('vocational', 'معهد متوسط/مهني'),
    Choice('bachelor', 'إجازة جامعية'),
    Choice('master', 'ماجستير'),
    Choice('phd', 'دكتوراه'),
  ];

  static const employmentStatuses = <Choice>[
    Choice('employed_formal', 'عمل رسمي'),
    Choice('employed_informal', 'عمل غير رسمي'),
    Choice('self_employed', 'عمل حر'),
    Choice('daily_labor', 'عمل بالمياومة'),
    Choice('unemployed_seeking', 'عاطل يبحث عن عمل'),
    Choice('unemployed_not_seeking', 'عاطل لا يبحث'),
    Choice('unable_to_work', 'غير قادر على العمل (لأسباب صحية)'),
    Choice('student', 'طالب'),
    Choice('retired', 'متقاعد'),
    Choice('housewife', 'ربّة منزل'),
  ];

  static const foodSecurityLevels = <Choice>[
    Choice('good', 'أمن غذائي جيد'),
    Choice('moderate', 'متوسط'),
    Choice('poor', 'ضعيف'),
    Choice('severe', 'انعدام أمن غذائي حاد'),
  ];

  static const priorities = <Choice>[
    Choice('none', 'لا حاجة'),
    Choice('low', 'منخفض'),
    Choice('medium', 'متوسط'),
    Choice('high', 'عالي'),
    Choice('critical', 'حرج/طارئ'),
  ];

  // ============ مراكز الاحتجاز ============
  // القيمة = الاسم العربي (يطابق name_ar في السيرفر؛ يُحلّ عند المزامنة).
  static List<Choice> get facilities {
    final list = _facilityNames
        .map((n) => Choice(n, n))
        .toList();
    list.add(const Choice('__other__', 'أخرى — غير مدرجة (اكتبها في الحقل التالي)'));
    return list;
  }

  static const _facilityNames = <String>[
    // دمشق وريفها
    'المخابرات العسكرية - الفرع 291',
    'فرع فلسطين - الفرع 235',
    'فرع الأمن الخارجي - الفرع 279',
    'فرع المداهمة والاقتحام - الفرع 215',
    'فرع الدوريات - الفرع 216',
    'فرع التحقيق العسكري - الفرع 248',
    'فرع المنطقة للمخابرات العسكرية - الفرع 227',
    'فرع أمن الضباط - الفرع 293',
    'فرع أمن القوات العسكرية - الفرع 294',
    'الفرع الفني - الفرع 211',
    'فرع الاتصالات - الفرع 225',
    'فرع اللاسلكي - الفرع 237',
    'فرع المعلومات بالمخابرات العسكرية',
    'فرع المدينة - المخابرات العسكرية',
    'فرع ريف دمشق للأمن العسكري',
    'فرع التحقيقات العسكرية - الفرع 228',
    'فرع الميسات',
    'المخابرات الجوية',
    'المخابرات الجوية - فرع مطار المزة',
    'فرع المخابرات الجوية للمنطقة',
    'المخابرات العامة / أمن الدولة - الفرع 285',
    'فرع أمن الدولة - الفرع 251 (الخطيب)',
    'فرع المعلومات بأمن الدولة - الفرع 255',
    'فرع التجسس - الفرع 300',
    'فرع المداهمة والاقتحام بأمن الدولة - الفرع 295',
    'الأمن السياسي - دمشق',
    'فرع المعلومات بالأمن السياسي',
    'فرع التحقيق بالأمن السياسي',
    'فرع العمليات بالأمن السياسي',
    'فرع الأحزاب السياسية',
    'فرع الطلاب والأنشطة الطلابية',
    'فرع السجون بالأمن السياسي',
    'فرع ريف دمشق للأمن السياسي',
    'فرع الجبة للأمن السياسي',
    'فرع التحقيقات السياسية',
    'فرع مكافحة الإرهاب',
    'فرع الأمن الجنائي - دمشق',
    'سجن عدرا المركزي',
    'سجن صيدنايا الأحمر',
    'سجن صيدنايا الأبيض',
    'مركز الدفاع الوطني - دمشق',
    'مركز الدفاع الوطني - ريف دمشق',
    // حلب
    'فرع أمن الدولة - الفرع 322',
    'فرع المخابرات الجوية - حلب',
    'فرع الأمن السياسي - حلب',
    'الأمن العسكري - حلب - الفرع 290',
    'مركز الدفاع الوطني - حلب',
    'سجن حلب المركزي',
    // حمص
    'المخابرات العسكرية - حمص',
    'فرع الأمن العسكري - حمص - الفرع 261',
    'المخابرات الجوية - حمص',
    'المخابرات العامة - حمص - الفرع 318',
    'الأمن السياسي - حمص',
    'فرع الأمن الجنائي - حمص',
    'سجن البالونة',
    'سجن البالونة الجديد',
    'كنيسة دير مخلص (مكان احتجاز)',
    'سجن تدمر',
    'سجن حمص المركزي',
    'مركز الدفاع الوطني - حمص',
    // حماة
    'فرع الأمن العسكري - حماة - الفرع 219',
    'فرع أمن الدولة - حماة',
    'فرع المخابرات الجوية - حماة',
    'فرع الأمن السياسي - حماة',
    'فرع الأمن الجنائي - حماة',
    'فرع التحقيق - حماة',
    'قسم الدوريات والمراقبة - حماة',
    'سجن حماة المركزي',
    'مركز الدفاع الوطني - حماة',
    // إدلب
    'المخابرات العسكرية - إدلب - الفرع 271',
    'أمن الدولة - إدلب',
    'الأمن السياسي - إدلب',
    'المخابرات الجوية - إدلب',
    'قسم الإرهاب في الأمن العسكري - إدلب',
    'مفرزة أمنية - جسر الشغور',
    'مفرزة أمنية - سراقب',
    'مفرزة أمنية - حارم',
    'مفرزة أمنية - معبر باب الهوى',
    'مفرزة أمنية - معرة النعمان',
    'مفرزة الأمن السياسي - خان شيخون',
    'مفرزة الأمن السياسي - أريحا',
    'مركز الدفاع الوطني - إدلب',
    // درعا
    'المخابرات العسكرية - درعا - الفرع 245',
    'المخابرات الجوية - درعا',
    'الأمن السياسي - درعا',
    'مركز الدفاع الوطني - درعا',
    // اللاذقية
    'المخابرات الجوية - اللاذقية',
    'المخابرات العامة - اللاذقية',
    'الأمن السياسي - اللاذقية',
    'فرع أمن الدولة - اللاذقية',
    'الأمن العسكري - اللاذقية',
    'فرع الأمن الجنائي - اللاذقية',
    'السجن المركزي - اللاذقية',
    'مدرسة جول جمال (مكان احتجاز)',
    'المركز الرياضي بالرمل الجنوبي (مكان احتجاز)',
    'مركز الدفاع الوطني - اللاذقية',
    // دير الزور
    'فرع الأمن العسكري - دير الزور - الفرع 243',
    'فرع الأمن السياسي - دير الزور',
    'الأمن العام - دير الزور - الفرع 327',
    'المخابرات الجوية - دير الزور',
    'سجن دير الزور المركزي',
    'مركز الدفاع الوطني - دير الزور',
    // الحسكة
    'المخابرات العسكرية - الحسكة - الفرع 222',
    'المخابرات الجوية - الحسكة',
    'أمن الدولة - الحسكة',
    'الأمن السياسي - الحسكة',
    'الأمن العسكري في الشدادي',
    'مركز الدفاع الوطني - الحسكة',
    // طرطوس
    'الأمن العسكري - طرطوس',
    'المخابرات الجوية - طرطوس',
    'أمن الدولة - طرطوس',
    'الأمن العسكري - بانياس',
    'مركز الدفاع الوطني - طرطوس',
    // الرقة
    'الأمن العسكري - الرقة',
    'المخابرات الجوية - الرقة',
    'الأمن السياسي - الرقة',
    'أمن الدولة - الرقة',
    'مركز الدفاع الوطني - الرقة',
    // السويداء
    'الأمن العسكري - السويداء',
    'أمن الدولة - السويداء',
    'الأمن السياسي - السويداء',
    'مركز الدفاع الوطني - السويداء',
    // القنيطرة
    'فرع الأمن السياسي - القنيطرة',
    'فرع أمن الدولة - القنيطرة',
    'المخابرات الجوية - القنيطرة',
    'فرع سعسع - الفرع 220',
    'مركز الدفاع الوطني - القنيطرة',
    // أخرى
    'فرع البادية - الفرع 221',
  ];

  // ============ أنماط التعذيب (اختيار متعدد) ============
  // القيمة = الاسم العربي (يطابق name_ar في السيرفر).
  static List<Choice> get tortureMethods =>
      _tortureMethodNames.map((n) => Choice(n, n)).toList();

  static const _tortureMethodNames = <String>[
    'الضرب بالكابلات والعصي',
    'الفلقة (ضرب أسفل القدمين)',
    'الشبح (التعليق من اليدين)',
    'الدولاب',
    'الكرسي الألماني',
    'الصعق الكهربائي',
    'حرق بالسجائر',
    'الإغراق الوهمي',
    'خلع الأظافر/الأسنان',
    'كسر العظام',
    'بساط الريح',
    'التهديد بإيذاء الأهل',
    'التهديد بالإعدام (الإعدام الوهمي)',
    'الحبس الانفرادي المطوّل',
    'إجبار على مشاهدة تعذيب آخرين',
    'إجبار على تكرار شعارات',
    'الإهانات والشتائم',
    'التهديد بالاغتصاب',
    'التحرش/الاعتداء الجنسي',
    'الاغتصاب',
    'التعرية القسرية',
    'التفتيش العاري',
    'الاكتظاظ الشديد',
    'الحرارة/البرودة الشديدة',
    'الحرمان من التهوية',
    'الإضاءة المستمرة أو الظلام الدائم',
    'الضوضاء العالية المستمرة',
    'الحرمان من الطعام',
    'الحرمان من الماء',
    'الحرمان من النوم',
    'الحرمان من العلاج',
    'الحرمان من استخدام المرحاض',
    'الحرمان من النظافة',
  ];
}
