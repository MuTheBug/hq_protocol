/// نموذج بيانات الناجي - يطابق Django model
/// يدعم: تحويل من/إلى JSON (للـAPI)، من/إلى Map (للـSQLite)
class Survivor {
  // مفاتيح
  int? id; // معرّف السيرفر - null للملفات المحلية فقط
  String? localId; // UUID محلي للملفات الجديدة قبل المزامنة
  String caseReference;
  String? caseUid;

  // الاسم
  String firstName;
  String fatherName;
  String? grandfatherName;
  String familyName;
  String? motherName;
  String? alias;

  // الهوية
  String? nationalId;
  String? birthDate;
  bool birthDateApproximate;
  String? birthGovernorate;
  String? birthPlaceDetail;
  String gender;
  String nationality;
  String? maritalStatusAtDetention;

  // وقت الاعتقال
  String? addressAtDetention;
  String? governorateAtDetention;
  String? occupationCategory;
  String? occupationDetail;
  String? politicalActivityCategory;
  String? politicalActivityDetail;

  // الاتصال
  String? currentPhone;
  String? currentEmail;
  String? currentCountry;
  String? currentGovernorate;
  String? currentCity;
  String? nextOfKinName;
  String? nextOfKinRelation;
  String? nextOfKinPhone;

  // التصنيف
  String fileClassification;
  int reliabilityScore;
  int corroborationScore;
  int completenessScore;
  double overallScore;

  // متاداتا
  bool isArchived;
  String? createdAt;
  String? updatedAt;

  // علم المزامنة - true إذا الملف غير مُزامَن مع السيرفر
  bool needsSync;
  String? syncError;

  Survivor({
    this.id,
    this.localId,
    required this.caseReference,
    this.caseUid,
    required this.firstName,
    required this.fatherName,
    this.grandfatherName,
    required this.familyName,
    this.motherName,
    this.alias,
    this.nationalId,
    this.birthDate,
    this.birthDateApproximate = false,
    this.birthGovernorate,
    this.birthPlaceDetail,
    required this.gender,
    this.nationality = 'سورية',
    this.maritalStatusAtDetention,
    this.addressAtDetention,
    this.governorateAtDetention,
    this.occupationCategory,
    this.occupationDetail,
    this.politicalActivityCategory,
    this.politicalActivityDetail,
    this.currentPhone,
    this.currentEmail,
    this.currentCountry,
    this.currentGovernorate,
    this.currentCity,
    this.nextOfKinName,
    this.nextOfKinRelation,
    this.nextOfKinPhone,
    this.fileClassification = 'draft',
    this.reliabilityScore = 0,
    this.corroborationScore = 0,
    this.completenessScore = 0,
    this.overallScore = 0.0,
    this.isArchived = false,
    this.createdAt,
    this.updatedAt,
    this.needsSync = false,
    this.syncError,
  });

  String get fullName {
    final parts = [firstName, fatherName, grandfatherName, familyName]
        .where((p) => p != null && p.isNotEmpty)
        .toList();
    return parts.join(' ');
  }

  /// تحويل من JSON الـAPI
  factory Survivor.fromJson(Map<String, dynamic> j) => Survivor(
        id: j['id'] as int?,
        caseReference: j['case_reference'] ?? '',
        caseUid: j['case_uid']?.toString(),
        firstName: j['first_name'] ?? '',
        fatherName: j['father_name'] ?? '',
        grandfatherName: j['grandfather_name'],
        familyName: j['family_name'] ?? '',
        motherName: j['mother_name'],
        alias: j['alias'],
        nationalId: j['national_id'],
        birthDate: j['birth_date'],
        birthDateApproximate: j['birth_date_approximate'] ?? false,
        birthGovernorate: j['birth_governorate'],
        birthPlaceDetail: j['birth_place_detail'],
        gender: j['gender'] ?? '',
        nationality: j['nationality'] ?? 'سورية',
        maritalStatusAtDetention: j['marital_status_at_detention'],
        addressAtDetention: j['address_at_detention'],
        governorateAtDetention: j['governorate_at_detention'],
        occupationCategory: j['occupation_category'],
        occupationDetail: j['occupation_detail'],
        politicalActivityCategory: j['political_activity_category'],
        politicalActivityDetail: j['political_activity_detail'],
        currentPhone: j['current_phone'],
        currentEmail: j['current_email'],
        currentCountry: j['current_country'],
        currentGovernorate: j['current_governorate'],
        currentCity: j['current_city'],
        nextOfKinName: j['next_of_kin_name'],
        nextOfKinRelation: j['next_of_kin_relation'],
        nextOfKinPhone: j['next_of_kin_phone'],
        fileClassification: j['file_classification'] ?? 'draft',
        reliabilityScore: j['reliability_score'] ?? 0,
        corroborationScore: j['corroboration_score'] ?? 0,
        completenessScore: j['completeness_score'] ?? 0,
        overallScore: (j['overall_score'] ?? 0).toDouble(),
        isArchived: j['is_archived'] ?? false,
        createdAt: j['created_at'],
        updatedAt: j['updated_at'],
        needsSync: false,
      );

  /// إلى JSON للإرسال للـAPI (الحقول القابلة للكتابة فقط)
  Map<String, dynamic> toApiJson() {
    final m = <String, dynamic>{
      'case_reference': caseReference,
      'first_name': firstName,
      'father_name': fatherName,
      'family_name': familyName,
      'gender': gender,
      'nationality': nationality,
      'file_classification': fileClassification,
      'birth_date_approximate': birthDateApproximate,
    };
    void put(String k, dynamic v) {
      if (v != null && v != '') m[k] = v;
    }
    put('grandfather_name', grandfatherName);
    put('mother_name', motherName);
    put('alias', alias);
    put('national_id', nationalId);
    put('birth_date', birthDate);
    put('birth_governorate', birthGovernorate);
    put('birth_place_detail', birthPlaceDetail);
    put('marital_status_at_detention', maritalStatusAtDetention);
    put('address_at_detention', addressAtDetention);
    put('governorate_at_detention', governorateAtDetention);
    put('occupation_category', occupationCategory);
    put('occupation_detail', occupationDetail);
    put('political_activity_category', politicalActivityCategory);
    put('political_activity_detail', politicalActivityDetail);
    put('current_phone', currentPhone);
    put('current_email', currentEmail);
    put('current_country', currentCountry);
    put('current_governorate', currentGovernorate);
    put('current_city', currentCity);
    put('next_of_kin_name', nextOfKinName);
    put('next_of_kin_relation', nextOfKinRelation);
    put('next_of_kin_phone', nextOfKinPhone);
    if (localId != null) m['_local_id'] = localId;
    return m;
  }

  /// تحويل لـMap لتخزينه في SQLite
  Map<String, dynamic> toDbMap() => {
        'id': id,
        'local_id': localId,
        'case_reference': caseReference,
        'case_uid': caseUid,
        'first_name': firstName,
        'father_name': fatherName,
        'grandfather_name': grandfatherName,
        'family_name': familyName,
        'mother_name': motherName,
        'alias': alias,
        'national_id': nationalId,
        'birth_date': birthDate,
        'birth_date_approximate': birthDateApproximate ? 1 : 0,
        'birth_governorate': birthGovernorate,
        'birth_place_detail': birthPlaceDetail,
        'gender': gender,
        'nationality': nationality,
        'marital_status_at_detention': maritalStatusAtDetention,
        'address_at_detention': addressAtDetention,
        'governorate_at_detention': governorateAtDetention,
        'occupation_category': occupationCategory,
        'occupation_detail': occupationDetail,
        'political_activity_category': politicalActivityCategory,
        'political_activity_detail': politicalActivityDetail,
        'current_phone': currentPhone,
        'current_email': currentEmail,
        'current_country': currentCountry,
        'current_governorate': currentGovernorate,
        'current_city': currentCity,
        'next_of_kin_name': nextOfKinName,
        'next_of_kin_relation': nextOfKinRelation,
        'next_of_kin_phone': nextOfKinPhone,
        'file_classification': fileClassification,
        'reliability_score': reliabilityScore,
        'corroboration_score': corroborationScore,
        'completeness_score': completenessScore,
        'overall_score': overallScore,
        'is_archived': isArchived ? 1 : 0,
        'created_at': createdAt,
        'updated_at': updatedAt,
        'needs_sync': needsSync ? 1 : 0,
        'sync_error': syncError,
      };

  factory Survivor.fromDbMap(Map<String, dynamic> m) => Survivor(
        id: m['id'] as int?,
        localId: m['local_id'],
        caseReference: m['case_reference'] ?? '',
        caseUid: m['case_uid'],
        firstName: m['first_name'] ?? '',
        fatherName: m['father_name'] ?? '',
        grandfatherName: m['grandfather_name'],
        familyName: m['family_name'] ?? '',
        motherName: m['mother_name'],
        alias: m['alias'],
        nationalId: m['national_id'],
        birthDate: m['birth_date'],
        birthDateApproximate: (m['birth_date_approximate'] ?? 0) == 1,
        birthGovernorate: m['birth_governorate'],
        birthPlaceDetail: m['birth_place_detail'],
        gender: m['gender'] ?? '',
        nationality: m['nationality'] ?? 'سورية',
        maritalStatusAtDetention: m['marital_status_at_detention'],
        addressAtDetention: m['address_at_detention'],
        governorateAtDetention: m['governorate_at_detention'],
        occupationCategory: m['occupation_category'],
        occupationDetail: m['occupation_detail'],
        politicalActivityCategory: m['political_activity_category'],
        politicalActivityDetail: m['political_activity_detail'],
        currentPhone: m['current_phone'],
        currentEmail: m['current_email'],
        currentCountry: m['current_country'],
        currentGovernorate: m['current_governorate'],
        currentCity: m['current_city'],
        nextOfKinName: m['next_of_kin_name'],
        nextOfKinRelation: m['next_of_kin_relation'],
        nextOfKinPhone: m['next_of_kin_phone'],
        fileClassification: m['file_classification'] ?? 'draft',
        reliabilityScore: m['reliability_score'] ?? 0,
        corroborationScore: m['corroboration_score'] ?? 0,
        completenessScore: m['completeness_score'] ?? 0,
        overallScore: (m['overall_score'] ?? 0).toDouble(),
        isArchived: (m['is_archived'] ?? 0) == 1,
        createdAt: m['created_at'],
        updatedAt: m['updated_at'],
        needsSync: (m['needs_sync'] ?? 0) == 1,
        syncError: m['sync_error'],
      );
}
