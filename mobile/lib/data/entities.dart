import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'field_spec.dart';
import 'reference_data.dart';

/// تعريفات كل الكيانات. مفاتيح الحقول تطابق أسماء حقول Django حرفياً
/// لتتوافق حزمة المزامنة مع السيرفر دون أي تحويل.

// ============================================================
// الملف الرئيسي للناجي
// ============================================================
final EntitySpec kSurvivorSpec = EntitySpec(
  table: 'survivor',
  titleAr: 'بيانات الناجي',
  icon: Icons.person,
  fields: [
    const FieldSpec('case_reference', 'رقم القضية الداخلي', FieldType.text,
        section: 'الهوية',
        required: true,
        help: 'يُولَّد آلياً. يمكنك تعديله إذا لزم.'),
    const FieldSpec('first_name', 'الاسم', FieldType.text,
        section: 'الهوية', required: true),
    const FieldSpec('father_name', 'اسم الأب', FieldType.text,
        section: 'الهوية', required: true),
    const FieldSpec('grandfather_name', 'اسم الجد', FieldType.text,
        section: 'الهوية'),
    const FieldSpec('family_name', 'اسم العائلة', FieldType.text,
        section: 'الهوية', required: true),
    const FieldSpec('mother_name', 'اسم الأم', FieldType.text,
        section: 'الهوية'),
    const FieldSpec('alias', 'الكنية/اللقب', FieldType.text, section: 'الهوية'),
    const FieldSpec('national_id', 'الرقم الوطني السوري', FieldType.text,
        section: 'الهوية', help: '11 رقماً (اختياري)'),
    FieldSpec('gender', 'الجنس', FieldType.choice,
        section: 'الهوية', choices: Ref.genders, required: true),
    const FieldSpec('birth_date', 'تاريخ الميلاد', FieldType.date,
        section: 'الهوية'),
    const FieldSpec('birth_date_approximate', 'تاريخ الميلاد تقريبي',
        FieldType.boolean,
        section: 'الهوية'),
    FieldSpec('birth_governorate', 'محافظة الولادة', FieldType.choice,
        section: 'الهوية', choices: Ref.governorates),
    const FieldSpec('birth_place_detail', 'مكان الولادة (مدينة/قرية/حي)',
        FieldType.text,
        section: 'الهوية'),
    const FieldSpec('nationality', 'الجنسية', FieldType.text, section: 'الهوية'),
    FieldSpec('marital_status_at_detention', 'الحالة الزوجية وقت الاعتقال',
        FieldType.choice,
        section: 'الهوية', choices: Ref.maritalStatuses),

    // وقت الاعتقال
    const FieldSpec('address_at_detention', 'عنوان السكن وقت الاعتقال',
        FieldType.multiline,
        section: 'وقت الاعتقال'),
    FieldSpec('governorate_at_detention', 'المحافظة وقت الاعتقال',
        FieldType.choice,
        section: 'وقت الاعتقال', choices: Ref.governorates),
    FieldSpec('occupation_category', 'فئة العمل/الدراسة وقت الاعتقال',
        FieldType.choice,
        section: 'وقت الاعتقال', choices: Ref.occupations),
    const FieldSpec('occupation_detail', 'تفاصيل العمل', FieldType.text,
        section: 'وقت الاعتقال'),
    FieldSpec('political_activity_category', 'فئة النشاط السياسي',
        FieldType.choice,
        section: 'وقت الاعتقال', choices: Ref.politicalActivities),
    const FieldSpec('political_activity_detail', 'تفاصيل النشاط السياسي',
        FieldType.multiline,
        section: 'وقت الاعتقال'),

    // الإقامة الحالية
    const FieldSpec('current_phone', 'رقم الهاتف الحالي', FieldType.text,
        section: 'الإقامة الحالية'),
    const FieldSpec('current_email', 'البريد الإلكتروني', FieldType.text,
        section: 'الإقامة الحالية'),
    FieldSpec('current_country', 'بلد الإقامة الحالي', FieldType.choice,
        section: 'الإقامة الحالية', choices: Ref.countries),
    FieldSpec('current_governorate', 'المحافظة الحالية (داخل سوريا)',
        FieldType.choice,
        section: 'الإقامة الحالية', choices: Ref.governorates),
    const FieldSpec('current_city', 'المدينة/البلدة الحالية', FieldType.text,
        section: 'الإقامة الحالية'),
    const FieldSpec('next_of_kin_name', 'اسم قريب للتواصل', FieldType.text,
        section: 'الإقامة الحالية'),
    const FieldSpec('next_of_kin_relation', 'صلة القرابة', FieldType.text,
        section: 'الإقامة الحالية'),
    const FieldSpec('next_of_kin_phone', 'رقم القريب', FieldType.text,
        section: 'الإقامة الحالية'),

    // الصور
    const FieldSpec('photo_recent', 'صورة حديثة للناجي', FieldType.image,
        section: 'الصور',
        help: 'التقط أو اختر صورة شخصية حديثة'),
    const FieldSpec(
        'photo_before_detention', 'صورة قبل الاعتقال', FieldType.image,
        section: 'الصور',
        help: 'صورة سابقة (إن أمكن) لمساعدة التعرّف على الهوية'),

    // التصنيف والإحالات
    FieldSpec('file_classification', 'تصنيف الملف', FieldType.choice,
        section: 'التصنيف والإحالات', choices: Ref.fileClassifications),
    const FieldSpec('medical_referral_offered', 'عُرضت إحالة طبية',
        FieldType.boolean,
        section: 'التصنيف والإحالات'),
    const FieldSpec('psychological_referral_offered', 'عُرضت إحالة نفسية',
        FieldType.boolean,
        section: 'التصنيف والإحالات'),
    const FieldSpec('legal_aid_offered', 'عُرضت مساعدة قانونية',
        FieldType.boolean,
        section: 'التصنيف والإحالات'),
    const FieldSpec('referral_notes', 'تفاصيل الإحالات', FieldType.multiline,
        section: 'التصنيف والإحالات'),
  ],
);

// ============================================================
// الموافقة المستنيرة
// ============================================================
final EntitySpec kConsentSpec = EntitySpec(
  table: 'consent',
  titleAr: 'الموافقة المستنيرة',
  icon: Icons.verified_user,
  singleton: true,
  fields: [
    const FieldSpec('consent_documented', 'تم أخذ الموافقة المستنيرة',
        FieldType.boolean,
        section: 'التوثيق'),
    const FieldSpec('consent_date', 'تاريخ الموافقة', FieldType.date,
        section: 'التوثيق'),
    const FieldSpec('consent_witness', 'شاهد على الموافقة', FieldType.text,
        section: 'التوثيق'),
    const FieldSpec('share_with_iiim', 'مشاركة مع الـIIIM', FieldType.boolean,
        section: 'مع مَن تُشارَك المعلومات'),
    const FieldSpec('share_with_coi', 'مشاركة مع لجنة التحقيق الأممية',
        FieldType.boolean,
        section: 'مع مَن تُشارَك المعلومات'),
    const FieldSpec('share_with_icc', 'مشاركة مع المحكمة الجنائية الدولية',
        FieldType.boolean,
        section: 'مع مَن تُشارَك المعلومات'),
    const FieldSpec('share_with_universal_jurisdiction',
        'مشاركة مع محاكم الولاية القضائية العالمية', FieldType.boolean,
        section: 'مع مَن تُشارَك المعلومات'),
    const FieldSpec('share_with_partner_orgs', 'مشاركة مع منظمات شريكة',
        FieldType.boolean,
        section: 'مع مَن تُشارَك المعلومات'),
    const FieldSpec('share_with_media', 'مشاركة مع الإعلام', FieldType.boolean,
        section: 'مع مَن تُشارَك المعلومات'),
    const FieldSpec('share_publicly', 'نشر علني', FieldType.boolean,
        section: 'مع مَن تُشارَك المعلومات'),
    const FieldSpec('anonymize_name', 'إخفاء الاسم', FieldType.boolean,
        section: 'إخفاء الهوية'),
    const FieldSpec('anonymize_photo', 'إخفاء الصورة', FieldType.boolean,
        section: 'إخفاء الهوية'),
    const FieldSpec('anonymize_location', 'إخفاء الموقع', FieldType.boolean,
        section: 'إخفاء الهوية'),
    const FieldSpec('anonymize_family_details', 'إخفاء تفاصيل العائلة',
        FieldType.boolean,
        section: 'إخفاء الهوية'),
    const FieldSpec('withdrawal_right_explained', 'شُرح حق الانسحاب',
        FieldType.boolean,
        section: 'الحقوق المشروحة'),
    const FieldSpec('confidentiality_limits_explained', 'شُرحت حدود السرّية',
        FieldType.boolean,
        section: 'الحقوق المشروحة'),
    const FieldSpec('intended_uses_explained', 'شُرحت الاستخدامات المحتملة',
        FieldType.boolean,
        section: 'الحقوق المشروحة'),
    const FieldSpec(
        'consent_form_file', 'صورة نموذج الموافقة الموقّع', FieldType.image,
        section: 'التوثيق',
        help: 'التقط صورة لنموذج الموافقة بعد توقيع الناجي'),
    const FieldSpec('consent_withdrawn', 'سُحبت الموافقة', FieldType.boolean,
        section: 'السحب'),
    const FieldSpec('withdrawal_date', 'تاريخ سحب الموافقة', FieldType.date,
        section: 'السحب'),
    const FieldSpec('withdrawal_reason', 'سبب السحب', FieldType.multiline,
        section: 'السحب'),
    const FieldSpec('notes', 'ملاحظات إضافية', FieldType.multiline,
        section: 'السحب'),
  ],
);

// ============================================================
// واقعة الاعتقال
// ============================================================
final EntitySpec kDetentionEventSpec = EntitySpec(
  table: 'detention_event',
  titleAr: 'وقائع الاعتقال',
  icon: Icons.gavel,
  fields: [
    const FieldSpec('detention_date', 'تاريخ الاعتقال', FieldType.date,
        required: true),
    const FieldSpec('date_approximate', 'التاريخ تقريبي', FieldType.boolean),
    const FieldSpec('detention_location', 'مكان الاعتقال', FieldType.text,
        required: true, help: 'شارع، نقطة تفتيش، البيت...'),
    FieldSpec('governorate', 'المحافظة', FieldType.choice,
        choices: Ref.governorates),
    const FieldSpec('arresting_entity', 'الجهة المعتقِلة', FieldType.text,
        required: true, help: 'مثال: المخابرات الجوية - فرع التحقيق'),
    const FieldSpec('arresting_personnel_details',
        'أسماء/رتب/علامات مميزة لعناصر الاعتقال', FieldType.multiline),
    const FieldSpec('reason_stated', 'السبب المُعلَن (إن وُجد)',
        FieldType.multiline),
    const FieldSpec('circumstances', 'ظروف الاعتقال بالتفصيل',
        FieldType.multiline,
        required: true),
    const FieldSpec('witnesses_to_arrest', 'شهود على الاعتقال',
        FieldType.multiline),
    const FieldSpec('family_notified', 'هل أُبلغت العائلة؟', FieldType.boolean),
    const FieldSpec('notes', 'ملاحظات', FieldType.multiline),
  ],
);

// ============================================================
// فترة الاحتجاز
// ============================================================
final EntitySpec kDetentionPeriodSpec = EntitySpec(
  table: 'detention_period',
  titleAr: 'فترات الاحتجاز',
  icon: Icons.lock_clock,
  fields: [
    FieldSpec('facility_name', 'مركز الاحتجاز', FieldType.choice,
        section: 'المكان والمدة', choices: Ref.facilities, required: true),
    const FieldSpec('facility_other', 'مركز آخر (إن لم يكن مدرجاً)',
        FieldType.text,
        section: 'المكان والمدة'),
    const FieldSpec('from_date', 'من تاريخ', FieldType.date,
        section: 'المكان والمدة', required: true),
    const FieldSpec('from_date_approximate', 'التاريخ تقريبي', FieldType.boolean,
        section: 'المكان والمدة'),
    const FieldSpec('to_date', 'إلى تاريخ', FieldType.date,
        section: 'المكان والمدة'),
    const FieldSpec('to_date_approximate', 'التاريخ تقريبي', FieldType.boolean,
        section: 'المكان والمدة'),
    const FieldSpec('order_index', 'ترتيب الفترة', FieldType.integer,
        section: 'المكان والمدة'),
    const FieldSpec('cell_description', 'وصف الزنزانة', FieldType.multiline,
        section: 'ظروف الاحتجاز'),
    const FieldSpec('cellmates_count', 'عدد المحتجزين معه', FieldType.integer,
        section: 'ظروف الاحتجاز'),
    const FieldSpec('food_water', 'الطعام والماء', FieldType.multiline,
        section: 'ظروف الاحتجاز'),
    const FieldSpec('sleep_conditions', 'ظروف النوم', FieldType.multiline,
        section: 'ظروف الاحتجاز'),
    const FieldSpec('hygiene_conditions', 'النظافة والحمّام', FieldType.multiline,
        section: 'ظروف الاحتجاز'),
    const FieldSpec('medical_care', 'الرعاية الطبية', FieldType.multiline,
        section: 'ظروف الاحتجاز'),
    const FieldSpec('contact_with_outside', 'التواصل مع الخارج',
        FieldType.multiline,
        section: 'ظروف الاحتجاز'),
    FieldSpec('torture_methods', 'أنماط التعذيب الموثَّقة', FieldType.multiChoice,
        section: 'الانتهاكات', choices: Ref.tortureMethods),
    const FieldSpec('torture_description', 'وصف تفصيلي للتعذيب (بأقوال الناجي)',
        FieldType.multiline,
        section: 'الانتهاكات'),
    const FieldSpec('sexual_violence_reported', 'بلاغ عن عنف جنسي',
        FieldType.boolean,
        section: 'الانتهاكات'),
    const FieldSpec('sexual_violence_details', 'تفاصيل العنف الجنسي (بحساسية)',
        FieldType.multiline,
        section: 'الانتهاكات'),
    const FieldSpec('witnessed_deaths', 'شهد على وفيات داخل المعتقل',
        FieldType.multiline,
        section: 'الانتهاكات'),
    const FieldSpec('witnessed_others', 'معتقلون آخرون شاهدهم',
        FieldType.multiline,
        section: 'الانتهاكات'),
    const FieldSpec('notes', 'ملاحظات إضافية', FieldType.multiline,
        section: 'الانتهاكات'),
  ],
);

// ============================================================
// واقعة الإفراج
// ============================================================
final EntitySpec kReleaseSpec = EntitySpec(
  table: 'release',
  titleAr: 'واقعة الإفراج',
  icon: Icons.lock_open,
  singleton: true,
  fields: [
    const FieldSpec('release_date', 'تاريخ الإفراج', FieldType.date,
        required: true),
    FieldSpec('release_type', 'نوع الإفراج', FieldType.choice,
        choices: Ref.releaseTypes, required: true),
    const FieldSpec('release_location', 'مكان الإفراج', FieldType.text),
    const FieldSpec('bribe_amount', 'قيمة الرشوة (إن وُجدت)', FieldType.text),
    const FieldSpec('conditions', 'شروط الإفراج', FieldType.multiline),
    const FieldSpec('circumstances', 'ظروف الإفراج', FieldType.multiline,
        required: true),
  ],
);

// ============================================================
// الشهود
// ============================================================
final EntitySpec kWitnessSpec = EntitySpec(
  table: 'witness',
  titleAr: 'الشهود',
  icon: Icons.groups,
  fields: [
    const FieldSpec('witness_name', 'اسم الشاهد', FieldType.text,
        section: 'الشاهد', required: true),
    const FieldSpec('witness_case_reference', 'رقم ملف الشاهد (إن وُجد)',
        FieldType.text,
        section: 'الشاهد'),
    const FieldSpec('witness_phone', 'هاتف الشاهد', FieldType.text,
        section: 'الشاهد'),
    const FieldSpec('witness_current_location', 'الموقع الحالي للشاهد',
        FieldType.text,
        section: 'الشاهد'),
    FieldSpec('facility_name', 'الفرع/المكان الذي رآه فيه', FieldType.choice,
        section: 'الشاهد', choices: Ref.facilities, required: true),
    const FieldSpec('facility_other', 'مركز آخر (إن لم يكن مدرجاً)',
        FieldType.text,
        section: 'الشاهد'),
    const FieldSpec('period_from', 'من تاريخ', FieldType.date,
        section: 'الشاهد', required: true),
    const FieldSpec('period_to', 'إلى تاريخ', FieldType.date, section: 'الشاهد'),
    const FieldSpec('cell_number', 'رقم الزنزانة (إن وُجد)', FieldType.text,
        section: 'الشاهد'),
    const FieldSpec('how_recognized', 'كيف تعرّف عليه؟', FieldType.multiline,
        section: 'الشهادة', required: true),
    const FieldSpec('distinguishing_details', 'تفاصيل مميزة لاحظها',
        FieldType.multiline,
        section: 'الشهادة'),
    const FieldSpec('specific_incidents', 'حوادث محددة شهدها',
        FieldType.multiline,
        section: 'الشهادة'),
    FieldSpec('relationship_before', 'علاقة الشاهد قبل الاعتقال',
        FieldType.choice,
        section: 'الشهادة', choices: Ref.witnessRelationships),
    const FieldSpec('is_independent', 'شاهد مستقل', FieldType.boolean,
        section: 'الاستقلالية والموافقة',
        help: 'لم يلتقِ بالناجي بعد الإفراج قبل الإدلاء بشهادته'),
    const FieldSpec('met_after_release', 'التقيا بعد الإفراج', FieldType.boolean,
        section: 'الاستقلالية والموافقة'),
    const FieldSpec('consent_to_use_testimony',
        'موافقة الشاهد على استخدام شهادته', FieldType.boolean,
        section: 'الاستقلالية والموافقة'),
    const FieldSpec('declaration_signed', 'بيان موقّع', FieldType.boolean,
        section: 'الاستقلالية والموافقة'),
    const FieldSpec('declaration_date', 'تاريخ البيان', FieldType.date,
        section: 'الاستقلالية والموافقة'),
    const FieldSpec(
        'declaration_file', 'صورة البيان الموقّع', FieldType.image,
        section: 'الاستقلالية والموافقة'),
    const FieldSpec('full_testimony', 'نص الشهادة الكامل', FieldType.multiline,
        section: 'الشهادة', required: true),
  ],
);

// ============================================================
// الوثائق الداعمة (تُسجَّل بياناتها الوصفية محلياً)
// ============================================================
final EntitySpec kDocumentSpec = EntitySpec(
  table: 'document',
  titleAr: 'الوثائق الداعمة',
  icon: Icons.description,
  fields: [
    FieldSpec('document_type', 'نوع الوثيقة', FieldType.choice,
        choices: Ref.documentTypes, required: true),
    const FieldSpec('title', 'عنوان الوثيقة', FieldType.text, required: true),
    const FieldSpec('description', 'الوصف والمحتوى', FieldType.multiline,
        required: true),
    const FieldSpec('source_description', 'مصدر الوثيقة وسلسلة الحيازة',
        FieldType.multiline,
        required: true, help: 'مَن، متى، أين، كيف'),
    const FieldSpec('date_obtained', 'تاريخ الاستلام', FieldType.date,
        required: true),
    const FieldSpec('file', 'صورة/مرفق الوثيقة', FieldType.image,
        help: 'التقط صورة للوثيقة أو اختر صورة موجودة (Screenshot)'),
    const FieldSpec('original_url', 'الرابط الأصلي', FieldType.text),
    const FieldSpec('url_archived_at', 'نسخة مؤرشفة (Archive.org)',
        FieldType.text),
    const FieldSpec('metadata_verified', 'تم التحقق من الميتاداتا',
        FieldType.boolean),
    const FieldSpec('forensic_analysis', 'التحليل الجنائي/التقني',
        FieldType.multiline),
    const FieldSpec('document_date', 'تاريخ الوثيقة نفسها', FieldType.date),
    const FieldSpec('document_reference_number', 'الرقم المرجعي للوثيقة',
        FieldType.text),
    const FieldSpec('issuing_authority', 'الجهة المُصدرة', FieldType.text),
    const FieldSpec('notes', 'ملاحظات', FieldType.multiline),
  ],
);

// ============================================================
// التقييم الطبي
// ============================================================
final EntitySpec kMedicalSpec = EntitySpec(
  table: 'medical',
  titleAr: 'التقييمات الطبية',
  icon: Icons.medical_services,
  fields: [
    FieldSpec('assessment_type', 'نوع التقييم', FieldType.choice,
        section: 'الفاحص', choices: Ref.assessmentTypes, required: true),
    const FieldSpec('assessment_date', 'تاريخ التقييم', FieldType.date,
        section: 'الفاحص', required: true),
    const FieldSpec('assessor_name', 'اسم الفاحص', FieldType.text,
        section: 'الفاحص', required: true),
    const FieldSpec('assessor_credentials', 'المؤهلات والاختصاص', FieldType.text,
        section: 'الفاحص', required: true),
    const FieldSpec('assessor_organization', 'المنظمة (مثل LDHR)', FieldType.text,
        section: 'الفاحص'),
    const FieldSpec('istanbul_protocol_compliant', 'متوافق مع بروتوكول إسطنبول',
        FieldType.boolean,
        section: 'الفاحص'),
    const FieldSpec('physical_findings', 'النتائج الجسدية', FieldType.multiline,
        section: 'النتائج'),
    const FieldSpec('scars_description', 'وصف الندوب والإصابات',
        FieldType.multiline,
        section: 'النتائج'),
    const FieldSpec('disabilities', 'الإعاقات المكتسبة', FieldType.multiline,
        section: 'النتائج'),
    const FieldSpec('psychological_findings', 'النتائج النفسية',
        FieldType.multiline,
        section: 'النتائج'),
    const FieldSpec('ptsd_indicators', 'علامات اضطراب ما بعد الصدمة',
        FieldType.boolean,
        section: 'النتائج'),
    const FieldSpec('depression_indicators', 'علامات اكتئاب', FieldType.boolean,
        section: 'النتائج'),
    const FieldSpec('anxiety_indicators', 'علامات قلق', FieldType.boolean,
        section: 'النتائج'),
    FieldSpec('consistency_with_account', 'مدى توافق النتائج مع الرواية',
        FieldType.choice,
        section: 'التوافق', choices: Ref.consistencyLevels),
    const FieldSpec('consistency_notes', 'ملاحظات على التوافق',
        FieldType.multiline,
        section: 'التوافق'),
    const FieldSpec('consent_to_share', 'موافقة على مشاركة التقرير',
        FieldType.boolean,
        section: 'التوافق'),
    const FieldSpec('report_file', 'صورة/مرفق التقرير الطبي', FieldType.image,
        section: 'التوافق', help: 'صورة لتقرير الفحص الموقّع'),
    const FieldSpec('notes', 'ملاحظات', FieldType.multiline, section: 'التوافق'),
  ],
);

// ============================================================
// الأثر طويل الأمد
// ============================================================
final EntitySpec kImpactSpec = EntitySpec(
  table: 'impact',
  titleAr: 'الأثر طويل الأمد',
  icon: Icons.healing,
  singleton: true,
  fields: [
    const FieldSpec('physical_injuries_permanent', 'إصابات جسدية دائمة',
        FieldType.multiline),
    const FieldSpec('chronic_illnesses', 'أمراض مزمنة ناتجة', FieldType.multiline),
    const FieldSpec('disabilities', 'إعاقات', FieldType.multiline),
    const FieldSpec('psychological_symptoms', 'الأعراض النفسية',
        FieldType.multiline),
    const FieldSpec('sleep_disorders', 'اضطرابات نوم', FieldType.boolean),
    const FieldSpec('flashbacks', 'استرجاع للذكريات', FieldType.boolean),
    const FieldSpec('social_withdrawal', 'انعزال اجتماعي', FieldType.boolean),
    const FieldSpec('family_impact', 'الأثر على العائلة', FieldType.multiline),
    const FieldSpec('work_impact', 'الأثر على القدرة على العمل',
        FieldType.multiline),
    const FieldSpec('education_impact', 'الأثر على التعليم', FieldType.multiline),
    const FieldSpec('financial_impact', 'الأثر المالي', FieldType.multiline),
    const FieldSpec('current_medications', 'الأدوية الحالية', FieldType.multiline),
    const FieldSpec('receiving_treatment', 'يتلقى علاجاً حالياً',
        FieldType.boolean),
    const FieldSpec('treatment_details', 'تفاصيل العلاج', FieldType.multiline),
  ],
);

// ============================================================
// المقابلات
// ============================================================
final EntitySpec kInterviewSpec = EntitySpec(
  table: 'interview',
  titleAr: 'المقابلات',
  icon: Icons.record_voice_over,
  fields: [
    const FieldSpec('sequence_number', 'رقم المقابلة', FieldType.integer,
        section: 'الجلسة'),
    const FieldSpec('is_first', 'هل هذه المقابلة الأولى؟', FieldType.boolean,
        section: 'الجلسة'),
    const FieldSpec('interview_date', 'تاريخ المقابلة', FieldType.date,
        section: 'الجلسة', required: true),
    const FieldSpec('duration_minutes', 'المدة بالدقائق', FieldType.integer,
        section: 'الجلسة'),
    FieldSpec('location_type', 'نوع المكان', FieldType.choice,
        section: 'الجلسة', choices: Ref.interviewLocations),
    const FieldSpec('location_detail', 'تفاصيل المكان', FieldType.text,
        section: 'الجلسة'),
    FieldSpec('language', 'لغة المقابلة', FieldType.choice,
        section: 'المنهجية', choices: Ref.interviewLanguages),
    FieldSpec('methodology', 'المنهجية المتّبعة', FieldType.choice,
        section: 'المنهجية', choices: Ref.interviewMethodologies),
    const FieldSpec('recorded', 'مسجَّلة', FieldType.boolean,
        section: 'المنهجية'),
    const FieldSpec('consent_to_record', 'موافقة على التسجيل', FieldType.boolean,
        section: 'المنهجية'),
    const FieldSpec('consent_to_publish_recording', 'موافقة على نشر التسجيل',
        FieldType.boolean,
        section: 'المنهجية'),
    const FieldSpec('summary', 'ملخص المقابلة', FieldType.multiline,
        section: 'المحتوى'),
    const FieldSpec('gender_appropriate',
        'روعيت اعتبارات النوع الاجتماعي', FieldType.boolean,
        section: 'المحتوى'),
    const FieldSpec('psychological_referral_after',
        'أُحيلت لدعم نفسي بعد المقابلة', FieldType.boolean,
        section: 'المحتوى'),
    const FieldSpec('notes', 'ملاحظات إضافية', FieldType.multiline,
        section: 'المحتوى'),
  ],
);

// ============================================================
// الملاحظات
// ============================================================
final EntitySpec kNoteSpec = EntitySpec(
  table: 'note',
  titleAr: 'الملاحظات',
  icon: Icons.sticky_note_2,
  fields: [
    FieldSpec('note_type', 'نوع الملاحظة', FieldType.choice,
        choices: Ref.noteTypes),
    const FieldSpec('title', 'عنوان مختصر', FieldType.text),
    const FieldSpec('content', 'الملاحظة', FieldType.multiline, required: true),
    const FieldSpec('is_pinned', 'مثبّتة في أعلى الملف', FieldType.boolean),
    const FieldSpec('is_confidential', 'سرّية (للمشرفين فقط)', FieldType.boolean),
  ],
);

// ============================================================
// المسح الاجتماعي - الأسرة
// ============================================================
final EntitySpec kHouseholdSpec = EntitySpec(
  table: 'household',
  titleAr: 'بيانات الأسرة',
  icon: Icons.family_restroom,
  singleton: true,
  fields: [
    FieldSpec('marital_status', 'الحالة الزوجية الحالية', FieldType.choice,
        section: 'الزواج', choices: Ref.householdMaritalStatuses, required: true),
    const FieldSpec('marital_status_changed_due_to_detention',
        'تغيرت الحالة الزوجية بسبب الاعتقال', FieldType.boolean,
        section: 'الزواج'),
    const FieldSpec('spouse_name', 'اسم الزوج/ة', FieldType.text,
        section: 'الزواج'),
    const FieldSpec('spouse_alive', 'الزوج/ة على قيد الحياة', FieldType.boolean,
        section: 'الزواج'),
    const FieldSpec('spouse_detained_now', 'الزوج/ة محتجز/ة حالياً',
        FieldType.boolean,
        section: 'الزواج'),
    const FieldSpec('spouse_detained_before', 'الزوج/ة سبق اعتقاله/ها',
        FieldType.boolean,
        section: 'الزواج'),
    const FieldSpec('spouse_employed', 'الزوج/ة يعمل/تعمل', FieldType.boolean,
        section: 'الزواج'),
    const FieldSpec('spouse_occupation', 'عمل الزوج/ة', FieldType.text,
        section: 'الزواج'),
    const FieldSpec('spouse_age', 'عمر الزوج/ة', FieldType.integer,
        section: 'الزواج'),
    const FieldSpec('household_size', 'إجمالي عدد أفراد الأسرة',
        FieldType.integer,
        section: 'الأفراد'),
    const FieldSpec('dependents_count', 'عدد المعالين كلياً', FieldType.integer,
        section: 'الأفراد'),
    const FieldSpec('children_count', 'عدد الأبناء', FieldType.integer,
        section: 'الأفراد'),
    FieldSpec('displacement_status', 'وضع التهجير', FieldType.choice,
        section: 'التهجير', choices: Ref.displacementStatuses),
    const FieldSpec('displacement_count', 'كم مرة تم التهجير؟', FieldType.integer,
        section: 'التهجير'),
    FieldSpec('original_governorate', 'المحافظة الأصلية', FieldType.choice,
        section: 'التهجير', choices: Ref.governorates),
    FieldSpec('current_governorate', 'المحافظة الحالية', FieldType.choice,
        section: 'التهجير', choices: Ref.governorates),
    const FieldSpec('survey_date', 'تاريخ المسح', FieldType.date,
        section: 'المسح', required: true),
    const FieldSpec('survey_location', 'مكان المسح', FieldType.text,
        section: 'المسح'),
    const FieldSpec('consent_to_survey', 'موافقة الناجي على المسح',
        FieldType.boolean,
        section: 'المسح'),
    const FieldSpec('survey_notes', 'ملاحظات الباحث', FieldType.multiline,
        section: 'المسح'),
  ],
);

// ============================================================
// المسح الاجتماعي - الأبناء
// ============================================================
final EntitySpec kChildSpec = EntitySpec(
  table: 'child',
  titleAr: 'الأبناء',
  icon: Icons.child_care,
  fields: [
    const FieldSpec('name', 'اسم الابن/الابنة', FieldType.text,
        section: 'أساسي', required: true),
    FieldSpec('gender', 'الجنس', FieldType.choice,
        section: 'أساسي', choices: Ref.childGenders, required: true),
    const FieldSpec('birth_date', 'تاريخ الميلاد', FieldType.date,
        section: 'أساسي'),
    const FieldSpec('age', 'العمر', FieldType.integer, section: 'أساسي'),
    const FieldSpec('is_in_school', 'يداوم في المدرسة', FieldType.boolean,
        section: 'التعليم'),
    FieldSpec('current_stage', 'المرحلة الدراسية الحالية', FieldType.choice,
        section: 'التعليم', choices: Ref.schoolStages),
    const FieldSpec('current_grade', 'الصف الحالي', FieldType.text,
        section: 'التعليم'),
    const FieldSpec('school_name', 'اسم المدرسة', FieldType.text,
        section: 'التعليم'),
    const FieldSpec('dropped_out', 'ترك الدراسة', FieldType.boolean,
        section: 'التعليم'),
    const FieldSpec('dropout_grade', 'الصف الذي تركها عنده', FieldType.text,
        section: 'التعليم'),
    const FieldSpec('dropout_year', 'سنة ترك الدراسة', FieldType.integer,
        section: 'التعليم'),
    const FieldSpec('dropout_due_to_father_detention',
        'ترك بسبب اعتقال الأب/الأم', FieldType.boolean,
        section: 'التعليم'),
    const FieldSpec('dropout_reason', 'سبب ترك الدراسة', FieldType.multiline,
        section: 'التعليم'),
    const FieldSpec('wants_to_resume_education', 'يرغب باستئناف التعليم',
        FieldType.boolean,
        section: 'التعليم'),
    const FieldSpec('has_disability', 'لديه إعاقة', FieldType.boolean,
        section: 'الصحة'),
    const FieldSpec('disability_description', 'وصف الإعاقة', FieldType.multiline,
        section: 'الصحة'),
    const FieldSpec('has_chronic_illness', 'لديه مرض مزمن', FieldType.boolean,
        section: 'الصحة'),
    const FieldSpec('chronic_illness_description', 'وصف المرض',
        FieldType.multiline,
        section: 'الصحة'),
    const FieldSpec('psychological_issues', 'معاناة نفسية ملحوظة',
        FieldType.boolean,
        section: 'الصحة'),
    const FieldSpec('psychological_notes', 'ملاحظات نفسية', FieldType.multiline,
        section: 'الصحة'),
    FieldSpec('work_status', 'وضع العمل', FieldType.choice,
        section: 'العمل', choices: Ref.childWorkTypes),
    const FieldSpec('work_description', 'وصف العمل (إن وُجد)', FieldType.text,
        section: 'العمل'),
    const FieldSpec('work_started_due_to_detention', 'بدأ العمل بسبب الاعتقال',
        FieldType.boolean,
        section: 'العمل'),
    const FieldSpec('notes', 'ملاحظات', FieldType.multiline, section: 'العمل'),
  ],
);

// ============================================================
// المسح الاجتماعي - السكن
// ============================================================
final EntitySpec kHousingSpec = EntitySpec(
  table: 'housing',
  titleAr: 'السكن',
  icon: Icons.house,
  singleton: true,
  fields: [
    FieldSpec('housing_type', 'نوع السكن', FieldType.choice,
        section: 'النوع', choices: Ref.housingTypes, required: true),
    const FieldSpec('rent_amount', 'قيمة الإيجار الشهري', FieldType.decimal,
        section: 'الإيجار'),
    FieldSpec('rent_currency', 'عملة الإيجار', FieldType.choice,
        section: 'الإيجار', choices: Ref.currencies),
    const FieldSpec('rent_overdue', 'متأخرات إيجار', FieldType.boolean,
        section: 'الإيجار'),
    const FieldSpec('rent_overdue_months', 'عدد أشهر التأخر', FieldType.integer,
        section: 'الإيجار'),
    const FieldSpec('threatened_with_eviction', 'مهدَّد بالإخراج من المنزل',
        FieldType.boolean,
        section: 'الإيجار'),
    const FieldSpec('rooms_count', 'عدد الغرف', FieldType.integer,
        section: 'الوصف'),
    const FieldSpec('residents_count', 'عدد القاطنين', FieldType.integer,
        section: 'الوصف'),
    FieldSpec('condition', 'الحالة العامة للسكن', FieldType.choice,
        section: 'الوصف', choices: Ref.housingConditions),
    const FieldSpec('has_electricity', 'كهرباء', FieldType.boolean,
        section: 'المرافق'),
    const FieldSpec('electricity_hours_per_day', 'ساعات الكهرباء يومياً',
        FieldType.integer,
        section: 'المرافق'),
    const FieldSpec('has_water', 'ماء', FieldType.boolean, section: 'المرافق'),
    const FieldSpec('has_heating', 'تدفئة', FieldType.boolean,
        section: 'المرافق'),
    const FieldSpec('has_sanitation', 'صرف صحي', FieldType.boolean,
        section: 'المرافق'),
    const FieldSpec('has_internet', 'إنترنت', FieldType.boolean,
        section: 'المرافق'),
    const FieldSpec('address', 'العنوان', FieldType.multiline, section: 'الموقع'),
    FieldSpec('governorate', 'المحافظة', FieldType.choice,
        section: 'الموقع', choices: Ref.governorates),
    const FieldSpec('city', 'المدينة/البلدة', FieldType.text, section: 'الموقع'),
    const FieldSpec('neighborhood', 'الحي', FieldType.text, section: 'الموقع'),
    const FieldSpec('owned_original_home_before',
        'كان يملك منزلاً قبل الاعتقال/التهجير', FieldType.boolean,
        section: 'الملكية الأصلية'),
    const FieldSpec('original_home_status', 'وضع المنزل الأصلي حالياً',
        FieldType.multiline,
        section: 'الملكية الأصلية'),
    const FieldSpec('property_confiscated', 'تمت مصادرة ممتلكاته',
        FieldType.boolean,
        section: 'الملكية الأصلية'),
    const FieldSpec('confiscation_details', 'تفاصيل المصادرة', FieldType.multiline,
        section: 'الملكية الأصلية'),
    const FieldSpec('notes', 'ملاحظات', FieldType.multiline,
        section: 'الملكية الأصلية'),
  ],
);

// ============================================================
// المسح الاجتماعي - التعليم
// ============================================================
final EntitySpec kEducationSpec = EntitySpec(
  table: 'education',
  titleAr: 'التعليم',
  icon: Icons.school,
  singleton: true,
  fields: [
    FieldSpec('highest_level_before_detention', 'أعلى مستوى قبل الاعتقال',
        FieldType.choice,
        choices: Ref.educationLevels, required: true),
    FieldSpec('highest_level_now', 'أعلى مستوى حالياً', FieldType.choice,
        choices: Ref.educationLevels, required: true),
    const FieldSpec('studies_interrupted_by_detention',
        'انقطع عن الدراسة بسبب الاعتقال', FieldType.boolean),
    const FieldSpec('field_of_study', 'التخصص', FieldType.text),
    const FieldSpec('institution', 'المؤسسة التعليمية', FieldType.text),
    const FieldSpec('is_currently_studying', 'يدرس حالياً', FieldType.boolean),
    const FieldSpec('current_program', 'البرنامج/المرحلة الحالية',
        FieldType.text),
    const FieldSpec('wants_to_resume', 'يرغب باستئناف التعليم', FieldType.boolean),
    const FieldSpec('obstacles_to_education', 'عقبات تحول دون استئناف التعليم',
        FieldType.multiline),
    const FieldSpec('languages_spoken', 'اللغات التي يجيدها', FieldType.text),
    const FieldSpec('has_certificates', 'لديه شهادات معتمدة', FieldType.boolean),
    const FieldSpec('certificates_details', 'تفاصيل الشهادات',
        FieldType.multiline),
    const FieldSpec('certificates_lost', 'فقد شهاداته بسبب الاعتقال/التهجير',
        FieldType.boolean),
  ],
);

// ============================================================
// المسح الاجتماعي - العمل والدخل
// ============================================================
final EntitySpec kEmploymentSpec = EntitySpec(
  table: 'employment',
  titleAr: 'العمل والدخل',
  icon: Icons.work,
  singleton: true,
  fields: [
    FieldSpec('status', 'وضع العمل الحالي', FieldType.choice,
        section: 'الوضع', choices: Ref.employmentStatuses, required: true),
    const FieldSpec('current_occupation', 'المهنة الحالية', FieldType.text,
        section: 'الوضع'),
    const FieldSpec('same_as_before', 'عاد لنفس المهنة السابقة',
        FieldType.boolean,
        section: 'الوضع'),
    const FieldSpec('unable_due_to_health', 'غير قادر على العمل لأسباب صحية',
        FieldType.boolean,
        section: 'الوضع'),
    const FieldSpec('unable_due_to_legal', 'غير قادر على العمل لأسباب قانونية',
        FieldType.boolean,
        section: 'الوضع'),
    const FieldSpec('monthly_income', 'الدخل الشهري التقريبي', FieldType.decimal,
        section: 'الدخل'),
    FieldSpec('income_currency', 'العملة', FieldType.choice,
        section: 'الدخل', choices: Ref.currencies),
    const FieldSpec('income_covers_basic_needs',
        'الدخل يغطي الاحتياجات الأساسية', FieldType.boolean,
        section: 'الدخل'),
    const FieldSpec('has_salary', 'راتب', FieldType.boolean,
        section: 'مصادر الدخل'),
    const FieldSpec('has_business_income', 'دخل من عمل تجاري', FieldType.boolean,
        section: 'مصادر الدخل'),
    const FieldSpec('has_pension', 'معاش تقاعدي', FieldType.boolean,
        section: 'مصادر الدخل'),
    const FieldSpec('has_remittance', 'حوالات من الخارج', FieldType.boolean,
        section: 'مصادر الدخل'),
    const FieldSpec('has_humanitarian_aid', 'مساعدات إنسانية', FieldType.boolean,
        section: 'مصادر الدخل'),
    const FieldSpec('has_family_support', 'مساعدات من الأهل', FieldType.boolean,
        section: 'مصادر الدخل'),
    const FieldSpec('other_income_sources', 'مصادر دخل أخرى', FieldType.multiline,
        section: 'مصادر الدخل'),
    const FieldSpec('work_hours_per_week', 'ساعات العمل الأسبوعية',
        FieldType.integer,
        section: 'مصادر الدخل'),
    const FieldSpec('notes', 'ملاحظات', FieldType.multiline,
        section: 'مصادر الدخل'),
  ],
);

// ============================================================
// المسح الاجتماعي - الصحة والرعاية
// ============================================================
final EntitySpec kHealthSpec = EntitySpec(
  table: 'health',
  titleAr: 'الصحة والرعاية',
  icon: Icons.local_hospital,
  singleton: true,
  fields: [
    const FieldSpec('has_health_insurance', 'لديه تأمين صحي', FieldType.boolean,
        section: 'الرعاية'),
    const FieldSpec('insurance_type', 'نوع التأمين', FieldType.text,
        section: 'الرعاية'),
    const FieldSpec('access_to_primary_care', 'وصول للرعاية الأولية',
        FieldType.boolean,
        section: 'الرعاية'),
    const FieldSpec('access_to_specialized_care', 'وصول للرعاية المتخصصة',
        FieldType.boolean,
        section: 'الرعاية'),
    const FieldSpec('distance_to_health_facility_km', 'بُعد أقرب مرفق صحي (كم)',
        FieldType.decimal,
        section: 'الرعاية'),
    const FieldSpec('chronic_illnesses_in_family', 'الأمراض المزمنة في الأسرة',
        FieldType.multiline,
        section: 'الحالة الصحية'),
    const FieldSpec('family_members_with_disability', 'عدد ذوي الإعاقة في الأسرة',
        FieldType.integer,
        section: 'الحالة الصحية'),
    const FieldSpec('psychological_support_received', 'يتلقى دعماً نفسياً',
        FieldType.boolean,
        section: 'الحالة الصحية'),
    const FieldSpec('psychological_support_provider', 'جهة الدعم النفسي',
        FieldType.text,
        section: 'الحالة الصحية'),
    const FieldSpec('medications_unaffordable', 'لا يستطيع تأمين الأدوية',
        FieldType.boolean,
        section: 'الحالة الصحية'),
    const FieldSpec('unmet_medical_needs', 'احتياجات طبية غير مُلبّاة',
        FieldType.multiline,
        section: 'الحالة الصحية'),
    FieldSpec('food_security', 'الأمن الغذائي', FieldType.choice,
        section: 'الغذاء', choices: Ref.foodSecurityLevels),
    const FieldSpec('meals_per_day', 'وجبات يومية', FieldType.integer,
        section: 'الغذاء'),
    const FieldSpec('notes', 'ملاحظات', FieldType.multiline, section: 'الغذاء'),
  ],
);

// ============================================================
// المسح الاجتماعي - تقييم الاحتياجات
// ============================================================
final EntitySpec kNeedsSpec = EntitySpec(
  table: 'needs',
  titleAr: 'تقييم الاحتياجات',
  icon: Icons.assignment,
  singleton: true,
  fields: [
    FieldSpec('financial_aid_priority', 'مساعدة مالية', FieldType.choice,
        section: 'أولويات المساعدة', choices: Ref.priorities),
    FieldSpec('food_aid_priority', 'مساعدة غذائية', FieldType.choice,
        section: 'أولويات المساعدة', choices: Ref.priorities),
    FieldSpec('housing_aid_priority', 'مساعدة إسكان', FieldType.choice,
        section: 'أولويات المساعدة', choices: Ref.priorities),
    FieldSpec('medical_aid_priority', 'مساعدة طبية', FieldType.choice,
        section: 'أولويات المساعدة', choices: Ref.priorities),
    FieldSpec('psychological_support_priority', 'دعم نفسي', FieldType.choice,
        section: 'أولويات المساعدة', choices: Ref.priorities),
    FieldSpec('legal_aid_priority', 'مساعدة قانونية', FieldType.choice,
        section: 'أولويات المساعدة', choices: Ref.priorities),
    FieldSpec('education_aid_priority', 'دعم تعليمي للأبناء', FieldType.choice,
        section: 'أولويات المساعدة', choices: Ref.priorities),
    FieldSpec('vocational_training_priority', 'تدريب مهني', FieldType.choice,
        section: 'أولويات المساعدة', choices: Ref.priorities),
    FieldSpec('documents_recovery_priority', 'استرداد وثائق رسمية',
        FieldType.choice,
        section: 'أولويات المساعدة', choices: Ref.priorities),
    const FieldSpec('needs_id_card', 'يحتاج هوية شخصية', FieldType.boolean,
        section: 'الوثائق المطلوبة'),
    const FieldSpec('needs_family_booklet', 'يحتاج دفتر عائلة', FieldType.boolean,
        section: 'الوثائق المطلوبة'),
    const FieldSpec('needs_passport', 'يحتاج جواز سفر', FieldType.boolean,
        section: 'الوثائق المطلوبة'),
    const FieldSpec('needs_birth_certificate', 'يحتاج شهادة ميلاد',
        FieldType.boolean,
        section: 'الوثائق المطلوبة'),
    const FieldSpec('needs_marriage_certificate', 'يحتاج وثيقة زواج',
        FieldType.boolean,
        section: 'الوثائق المطلوبة'),
    const FieldSpec('needs_security_clearance', 'يحتاج تسوية وضع أمني',
        FieldType.boolean,
        section: 'الوثائق المطلوبة'),
    const FieldSpec('additional_needs', 'احتياجات أخرى', FieldType.multiline,
        section: 'متابعة'),
    const FieldSpec('barriers_to_aid', 'عقبات الوصول للمساعدات',
        FieldType.multiline,
        section: 'متابعة'),
    const FieldSpec('assessment_date', 'تاريخ التقييم', FieldType.date,
        section: 'متابعة', required: true),
    const FieldSpec('follow_up_required', 'يحتاج متابعة', FieldType.boolean,
        section: 'متابعة'),
    const FieldSpec('follow_up_date', 'تاريخ المتابعة', FieldType.date,
        section: 'متابعة'),
    const FieldSpec('notes', 'ملاحظات', FieldType.multiline, section: 'متابعة'),
  ],
);

/// كل الكيانات المرتبطة بالناجي، بترتيب العرض في شاشة التفاصيل.
final List<EntitySpec> kRelatedEntities = [
  kConsentSpec,
  kDetentionEventSpec,
  kDetentionPeriodSpec,
  kReleaseSpec,
  kWitnessSpec,
  kDocumentSpec,
  kMedicalSpec,
  kImpactSpec,
  kInterviewSpec,
  kNoteSpec,
  kHouseholdSpec,
  kChildSpec,
  kHousingSpec,
  kEducationSpec,
  kEmploymentSpec,
  kHealthSpec,
  kNeedsSpec,
];

/// مجموعة "التوثيق" مقابل "المسح الاجتماعي" (لعرض الأقسام مجمَّعة).
const List<String> kDocumentationTables = [
  'consent',
  'detention_event',
  'detention_period',
  'release',
  'witness',
  'document',
  'medical',
  'impact',
  'interview',
  'note',
];

const List<String> kSocialTables = [
  'household',
  'child',
  'housing',
  'education',
  'employment',
  'health',
  'needs',
];

EntitySpec entityByTable(String table) {
  if (table == 'survivor') return kSurvivorSpec;
  return kRelatedEntities.firstWhere((e) => e.table == table);
}

/// رقم قضية مولّد آلياً (مطابق لصيغة `generate_case_reference()` في Django):
/// `HQ-<السنة>-<6 خانات هكساديسيمال>` — احتمال التصادم منخفض جداً.
String newCaseReference() {
  final year = DateTime.now().year;
  final rng = math.Random.secure();
  final bytes = List<int>.generate(3, (_) => rng.nextInt(256));
  final hex = bytes
      .map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase())
      .join();
  return 'HQ-$year-$hex';
}

/// القيم الافتراضية لسجل جديد (تطابق defaults في Django).
Map<String, dynamic> defaultsFor(String table) {
  switch (table) {
    case 'survivor':
      return {
        'case_reference': newCaseReference(),
        'nationality': 'سورية',
        'gender': 'male',
        'file_classification': 'draft',
      };
    case 'household':
      return {'household_size': 1, 'spouse_alive': true};
    case 'child':
      return {'is_in_school': true, 'current_stage': 'not_started'};
    case 'housing':
      return {'rooms_count': 1, 'residents_count': 1, 'rent_currency': 'SYP'};
    case 'employment':
      return {'income_currency': 'SYP'};
    case 'health':
      return {'meals_per_day': 3, 'food_security': 'moderate'};
    case 'needs':
      return {'follow_up_required': true};
    case 'interview':
      return {
        'sequence_number': 1,
        'is_first': true,
        'language': 'ar_levantine',
        'methodology': 'istanbul',
        'location_type': 'office',
      };
    case 'note':
      return {'note_type': 'general'};
    case 'detention_period':
      return {'order_index': 0};
    default:
      return {};
  }
}
