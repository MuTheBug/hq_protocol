/// النماذج الإضافية المتبقية - مطابقة لتطبيق الويب
/// تشمل: الوثائق، التقييم الطبي، الأثر طويل الأمد، المقابلات + الوسائط،
/// المسح الاجتماعي (الأسرة، الأطفال، السكن، التعليم، العمل، الصحة، الاحتياجات).

class SupportingDocument {
  int? id;
  String? localId;
  String? survivorLocalId;
  int? survivorId;
  String documentType;
  String title;
  String? description;
  String? filePath; // مسار محلي للملف على الجهاز - يُرفع عند المزامنة
  String? fileName;
  int? fileSizeBytes;
  String? sourceDescription;
  String? dateObtained;
  String? originalUrl;
  String? documentDate;
  String? documentReferenceNumber;
  String? issuingAuthority;
  String? notes;
  bool needsSync;

  SupportingDocument({
    this.id, this.localId, this.survivorLocalId, this.survivorId,
    this.documentType = 'other', required this.title, this.description,
    this.filePath, this.fileName, this.fileSizeBytes,
    this.sourceDescription, this.dateObtained,
    this.originalUrl, this.documentDate,
    this.documentReferenceNumber, this.issuingAuthority,
    this.notes, this.needsSync = false,
  });

  Map<String, dynamic> toDbMap() => {
    'local_id': localId, 'id': id,
    'survivor_local_id': survivorLocalId, 'survivor_id': survivorId,
    'document_type': documentType, 'title': title, 'description': description,
    'file_path': filePath, 'file_name': fileName,
    'file_size_bytes': fileSizeBytes,
    'source_description': sourceDescription, 'date_obtained': dateObtained,
    'original_url': originalUrl, 'document_date': documentDate,
    'document_reference_number': documentReferenceNumber,
    'issuing_authority': issuingAuthority,
    'notes': notes, 'needs_sync': needsSync ? 1 : 0,
  };

  factory SupportingDocument.fromDbMap(Map<String, dynamic> m) =>
      SupportingDocument(
        id: m['id'] as int?, localId: m['local_id'],
        survivorLocalId: m['survivor_local_id'],
        survivorId: m['survivor_id'] as int?,
        documentType: m['document_type'] ?? 'other',
        title: m['title'] ?? '', description: m['description'],
        filePath: m['file_path'], fileName: m['file_name'],
        fileSizeBytes: m['file_size_bytes'] as int?,
        sourceDescription: m['source_description'],
        dateObtained: m['date_obtained'],
        originalUrl: m['original_url'], documentDate: m['document_date'],
        documentReferenceNumber: m['document_reference_number'],
        issuingAuthority: m['issuing_authority'],
        notes: m['notes'], needsSync: (m['needs_sync'] ?? 0) == 1,
      );
}

class MedicalAssessment {
  int? id;
  String? localId;
  String? survivorLocalId;
  int? survivorId;
  String assessmentType;
  String assessmentDate;
  String assessorName;
  String assessorCredentials;
  String? assessorOrganization;
  bool istanbulProtocolCompliant;
  String? physicalFindings;
  String? scarsDescription;
  String? disabilities;
  String? psychologicalFindings;
  bool ptsdIndicators;
  bool depressionIndicators;
  bool anxietyIndicators;
  String consistencyWithAccount;
  String? consistencyNotes;
  bool consentToShare;
  String? notes;
  bool needsSync;

  MedicalAssessment({
    this.id, this.localId, this.survivorLocalId, this.survivorId,
    this.assessmentType = 'physical', required this.assessmentDate,
    required this.assessorName, this.assessorCredentials = '',
    this.assessorOrganization,
    this.istanbulProtocolCompliant = false,
    this.physicalFindings, this.scarsDescription, this.disabilities,
    this.psychologicalFindings,
    this.ptsdIndicators = false, this.depressionIndicators = false,
    this.anxietyIndicators = false,
    this.consistencyWithAccount = 'not_assessed', this.consistencyNotes,
    this.consentToShare = false, this.notes, this.needsSync = false,
  });

  Map<String, dynamic> toDbMap() => {
    'local_id': localId, 'id': id,
    'survivor_local_id': survivorLocalId, 'survivor_id': survivorId,
    'assessment_type': assessmentType, 'assessment_date': assessmentDate,
    'assessor_name': assessorName,
    'assessor_credentials': assessorCredentials,
    'assessor_organization': assessorOrganization,
    'istanbul_protocol_compliant': istanbulProtocolCompliant ? 1 : 0,
    'physical_findings': physicalFindings,
    'scars_description': scarsDescription, 'disabilities': disabilities,
    'psychological_findings': psychologicalFindings,
    'ptsd_indicators': ptsdIndicators ? 1 : 0,
    'depression_indicators': depressionIndicators ? 1 : 0,
    'anxiety_indicators': anxietyIndicators ? 1 : 0,
    'consistency_with_account': consistencyWithAccount,
    'consistency_notes': consistencyNotes,
    'consent_to_share': consentToShare ? 1 : 0,
    'notes': notes, 'needs_sync': needsSync ? 1 : 0,
  };

  factory MedicalAssessment.fromDbMap(Map<String, dynamic> m) =>
      MedicalAssessment(
        id: m['id'] as int?, localId: m['local_id'],
        survivorLocalId: m['survivor_local_id'],
        survivorId: m['survivor_id'] as int?,
        assessmentType: m['assessment_type'] ?? 'physical',
        assessmentDate: m['assessment_date'] ?? '',
        assessorName: m['assessor_name'] ?? '',
        assessorCredentials: m['assessor_credentials'] ?? '',
        assessorOrganization: m['assessor_organization'],
        istanbulProtocolCompliant:
            (m['istanbul_protocol_compliant'] ?? 0) == 1,
        physicalFindings: m['physical_findings'],
        scarsDescription: m['scars_description'],
        disabilities: m['disabilities'],
        psychologicalFindings: m['psychological_findings'],
        ptsdIndicators: (m['ptsd_indicators'] ?? 0) == 1,
        depressionIndicators: (m['depression_indicators'] ?? 0) == 1,
        anxietyIndicators: (m['anxiety_indicators'] ?? 0) == 1,
        consistencyWithAccount: m['consistency_with_account'] ?? 'not_assessed',
        consistencyNotes: m['consistency_notes'],
        consentToShare: (m['consent_to_share'] ?? 0) == 1,
        notes: m['notes'], needsSync: (m['needs_sync'] ?? 0) == 1,
      );
}

class LongTermImpact {
  int? id;
  String? localId;
  String? survivorLocalId;
  String? physicalInjuriesPermanent;
  String? chronicIllnesses;
  String? disabilities;
  String? psychologicalSymptoms;
  bool sleepDisorders;
  bool flashbacks;
  bool socialWithdrawal;
  String? familyImpact;
  String? workImpact;
  String? educationImpact;
  String? financialImpact;
  String? currentMedications;
  bool receivingTreatment;
  String? treatmentDetails;
  bool needsSync;

  LongTermImpact({
    this.id, this.localId, this.survivorLocalId,
    this.physicalInjuriesPermanent, this.chronicIllnesses, this.disabilities,
    this.psychologicalSymptoms,
    this.sleepDisorders = false, this.flashbacks = false,
    this.socialWithdrawal = false,
    this.familyImpact, this.workImpact, this.educationImpact,
    this.financialImpact, this.currentMedications,
    this.receivingTreatment = false, this.treatmentDetails,
    this.needsSync = false,
  });

  Map<String, dynamic> toDbMap() => {
    'local_id': localId, 'id': id,
    'survivor_local_id': survivorLocalId,
    'physical_injuries_permanent': physicalInjuriesPermanent,
    'chronic_illnesses': chronicIllnesses,
    'disabilities': disabilities,
    'psychological_symptoms': psychologicalSymptoms,
    'sleep_disorders': sleepDisorders ? 1 : 0,
    'flashbacks': flashbacks ? 1 : 0,
    'social_withdrawal': socialWithdrawal ? 1 : 0,
    'family_impact': familyImpact, 'work_impact': workImpact,
    'education_impact': educationImpact,
    'financial_impact': financialImpact,
    'current_medications': currentMedications,
    'receiving_treatment': receivingTreatment ? 1 : 0,
    'treatment_details': treatmentDetails,
    'needs_sync': needsSync ? 1 : 0,
  };

  factory LongTermImpact.fromDbMap(Map<String, dynamic> m) => LongTermImpact(
        id: m['id'] as int?, localId: m['local_id'],
        survivorLocalId: m['survivor_local_id'],
        physicalInjuriesPermanent: m['physical_injuries_permanent'],
        chronicIllnesses: m['chronic_illnesses'],
        disabilities: m['disabilities'],
        psychologicalSymptoms: m['psychological_symptoms'],
        sleepDisorders: (m['sleep_disorders'] ?? 0) == 1,
        flashbacks: (m['flashbacks'] ?? 0) == 1,
        socialWithdrawal: (m['social_withdrawal'] ?? 0) == 1,
        familyImpact: m['family_impact'], workImpact: m['work_impact'],
        educationImpact: m['education_impact'],
        financialImpact: m['financial_impact'],
        currentMedications: m['current_medications'],
        receivingTreatment: (m['receiving_treatment'] ?? 0) == 1,
        treatmentDetails: m['treatment_details'],
        needsSync: (m['needs_sync'] ?? 0) == 1,
      );
}

class Interview {
  int? id;
  String? localId;
  String? survivorLocalId;
  int? survivorId;
  int sequenceNumber;
  bool isFirst;
  String interviewDate;
  int? durationMinutes;
  String locationType;
  String? locationDetail;
  String language;
  String methodology;
  bool recorded;
  bool consentToRecord;
  bool consentToPublishRecording;
  String? summary;
  bool genderAppropriate;
  bool psychologicalReferralAfter;
  String? notes;
  bool needsSync;

  Interview({
    this.id, this.localId, this.survivorLocalId, this.survivorId,
    this.sequenceNumber = 1, this.isFirst = true,
    required this.interviewDate, this.durationMinutes,
    this.locationType = 'office', this.locationDetail,
    this.language = 'ar_levantine', this.methodology = 'istanbul',
    this.recorded = false, this.consentToRecord = false,
    this.consentToPublishRecording = false,
    this.summary, this.genderAppropriate = false,
    this.psychologicalReferralAfter = false,
    this.notes, this.needsSync = false,
  });

  Map<String, dynamic> toDbMap() => {
    'local_id': localId, 'id': id,
    'survivor_local_id': survivorLocalId, 'survivor_id': survivorId,
    'sequence_number': sequenceNumber, 'is_first': isFirst ? 1 : 0,
    'interview_date': interviewDate, 'duration_minutes': durationMinutes,
    'location_type': locationType, 'location_detail': locationDetail,
    'language': language, 'methodology': methodology,
    'recorded': recorded ? 1 : 0,
    'consent_to_record': consentToRecord ? 1 : 0,
    'consent_to_publish_recording': consentToPublishRecording ? 1 : 0,
    'summary': summary,
    'gender_appropriate': genderAppropriate ? 1 : 0,
    'psychological_referral_after': psychologicalReferralAfter ? 1 : 0,
    'notes': notes, 'needs_sync': needsSync ? 1 : 0,
  };

  factory Interview.fromDbMap(Map<String, dynamic> m) => Interview(
        id: m['id'] as int?, localId: m['local_id'],
        survivorLocalId: m['survivor_local_id'],
        survivorId: m['survivor_id'] as int?,
        sequenceNumber: m['sequence_number'] ?? 1,
        isFirst: (m['is_first'] ?? 0) == 1,
        interviewDate: m['interview_date'] ?? '',
        durationMinutes: m['duration_minutes'] as int?,
        locationType: m['location_type'] ?? 'office',
        locationDetail: m['location_detail'],
        language: m['language'] ?? 'ar_levantine',
        methodology: m['methodology'] ?? 'istanbul',
        recorded: (m['recorded'] ?? 0) == 1,
        consentToRecord: (m['consent_to_record'] ?? 0) == 1,
        consentToPublishRecording:
            (m['consent_to_publish_recording'] ?? 0) == 1,
        summary: m['summary'],
        genderAppropriate: (m['gender_appropriate'] ?? 0) == 1,
        psychologicalReferralAfter:
            (m['psychological_referral_after'] ?? 0) == 1,
        notes: m['notes'], needsSync: (m['needs_sync'] ?? 0) == 1,
      );
}

class HouseholdSurvey {
  int? id;
  String? localId;
  String? survivorLocalId;
  int? survivorId;
  String maritalStatus;
  bool maritalStatusChangedDueToDetention;
  String? spouseName;
  bool spouseAlive;
  bool spouseDetainedNow;
  bool spouseDetainedBefore;
  bool spouseEmployed;
  String? spouseOccupation;
  int? spouseAge;
  int householdSize;
  int dependentsCount;
  int childrenCount;
  String displacementStatus;
  int displacementCount;
  String? originalGovernorate;
  String? currentGovernorate;
  String surveyDate;
  String? surveyLocation;
  String? surveyNotes;
  bool consentToSurvey;
  bool needsSync;

  HouseholdSurvey({
    this.id, this.localId, this.survivorLocalId, this.survivorId,
    this.maritalStatus = 'single',
    this.maritalStatusChangedDueToDetention = false,
    this.spouseName, this.spouseAlive = true,
    this.spouseDetainedNow = false, this.spouseDetainedBefore = false,
    this.spouseEmployed = false, this.spouseOccupation, this.spouseAge,
    this.householdSize = 1, this.dependentsCount = 0, this.childrenCount = 0,
    this.displacementStatus = 'not_displaced', this.displacementCount = 0,
    this.originalGovernorate, this.currentGovernorate,
    required this.surveyDate, this.surveyLocation, this.surveyNotes,
    this.consentToSurvey = false, this.needsSync = false,
  });

  Map<String, dynamic> toDbMap() => {
    'local_id': localId, 'id': id,
    'survivor_local_id': survivorLocalId, 'survivor_id': survivorId,
    'marital_status': maritalStatus,
    'marital_status_changed_due_to_detention':
        maritalStatusChangedDueToDetention ? 1 : 0,
    'spouse_name': spouseName,
    'spouse_alive': spouseAlive ? 1 : 0,
    'spouse_detained_now': spouseDetainedNow ? 1 : 0,
    'spouse_detained_before': spouseDetainedBefore ? 1 : 0,
    'spouse_employed': spouseEmployed ? 1 : 0,
    'spouse_occupation': spouseOccupation, 'spouse_age': spouseAge,
    'household_size': householdSize,
    'dependents_count': dependentsCount,
    'children_count': childrenCount,
    'displacement_status': displacementStatus,
    'displacement_count': displacementCount,
    'original_governorate': originalGovernorate,
    'current_governorate': currentGovernorate,
    'survey_date': surveyDate, 'survey_location': surveyLocation,
    'survey_notes': surveyNotes,
    'consent_to_survey': consentToSurvey ? 1 : 0,
    'needs_sync': needsSync ? 1 : 0,
  };

  factory HouseholdSurvey.fromDbMap(Map<String, dynamic> m) => HouseholdSurvey(
        id: m['id'] as int?, localId: m['local_id'],
        survivorLocalId: m['survivor_local_id'],
        survivorId: m['survivor_id'] as int?,
        maritalStatus: m['marital_status'] ?? 'single',
        maritalStatusChangedDueToDetention:
            (m['marital_status_changed_due_to_detention'] ?? 0) == 1,
        spouseName: m['spouse_name'],
        spouseAlive: (m['spouse_alive'] ?? 1) == 1,
        spouseDetainedNow: (m['spouse_detained_now'] ?? 0) == 1,
        spouseDetainedBefore: (m['spouse_detained_before'] ?? 0) == 1,
        spouseEmployed: (m['spouse_employed'] ?? 0) == 1,
        spouseOccupation: m['spouse_occupation'],
        spouseAge: m['spouse_age'] as int?,
        householdSize: m['household_size'] ?? 1,
        dependentsCount: m['dependents_count'] ?? 0,
        childrenCount: m['children_count'] ?? 0,
        displacementStatus: m['displacement_status'] ?? 'not_displaced',
        displacementCount: m['displacement_count'] ?? 0,
        originalGovernorate: m['original_governorate'],
        currentGovernorate: m['current_governorate'],
        surveyDate: m['survey_date'] ?? '',
        surveyLocation: m['survey_location'],
        surveyNotes: m['survey_notes'],
        consentToSurvey: (m['consent_to_survey'] ?? 0) == 1,
        needsSync: (m['needs_sync'] ?? 0) == 1,
      );
}

class Child {
  int? id;
  String? localId;
  String? householdLocalId;
  String name;
  String gender;
  String? birthDate;
  int? age;
  bool isInSchool;
  String currentStage;
  String? currentGrade;
  String? schoolName;
  bool droppedOut;
  bool dropoutDueToFatherDetention;
  String? dropoutReason;
  String workStatus;
  bool hasDisability;
  String? disabilityDescription;
  bool hasChronicIllness;
  bool psychologicalIssues;
  String? notes;
  bool needsSync;

  Child({
    this.id, this.localId, this.householdLocalId,
    required this.name, this.gender = 'male', this.birthDate, this.age,
    this.isInSchool = true, this.currentStage = 'not_started',
    this.currentGrade, this.schoolName,
    this.droppedOut = false, this.dropoutDueToFatherDetention = false,
    this.dropoutReason, this.workStatus = 'student',
    this.hasDisability = false, this.disabilityDescription,
    this.hasChronicIllness = false, this.psychologicalIssues = false,
    this.notes, this.needsSync = false,
  });

  Map<String, dynamic> toDbMap() => {
    'local_id': localId, 'id': id,
    'household_local_id': householdLocalId,
    'name': name, 'gender': gender, 'birth_date': birthDate, 'age': age,
    'is_in_school': isInSchool ? 1 : 0,
    'current_stage': currentStage, 'current_grade': currentGrade,
    'school_name': schoolName,
    'dropped_out': droppedOut ? 1 : 0,
    'dropout_due_to_father_detention':
        dropoutDueToFatherDetention ? 1 : 0,
    'dropout_reason': dropoutReason,
    'work_status': workStatus,
    'has_disability': hasDisability ? 1 : 0,
    'disability_description': disabilityDescription,
    'has_chronic_illness': hasChronicIllness ? 1 : 0,
    'psychological_issues': psychologicalIssues ? 1 : 0,
    'notes': notes, 'needs_sync': needsSync ? 1 : 0,
  };

  factory Child.fromDbMap(Map<String, dynamic> m) => Child(
        id: m['id'] as int?, localId: m['local_id'],
        householdLocalId: m['household_local_id'],
        name: m['name'] ?? '', gender: m['gender'] ?? 'male',
        birthDate: m['birth_date'], age: m['age'] as int?,
        isInSchool: (m['is_in_school'] ?? 1) == 1,
        currentStage: m['current_stage'] ?? 'not_started',
        currentGrade: m['current_grade'], schoolName: m['school_name'],
        droppedOut: (m['dropped_out'] ?? 0) == 1,
        dropoutDueToFatherDetention:
            (m['dropout_due_to_father_detention'] ?? 0) == 1,
        dropoutReason: m['dropout_reason'],
        workStatus: m['work_status'] ?? 'student',
        hasDisability: (m['has_disability'] ?? 0) == 1,
        disabilityDescription: m['disability_description'],
        hasChronicIllness: (m['has_chronic_illness'] ?? 0) == 1,
        psychologicalIssues: (m['psychological_issues'] ?? 0) == 1,
        notes: m['notes'], needsSync: (m['needs_sync'] ?? 0) == 1,
      );
}

class HousingInfo {
  int? id;
  String? localId;
  String? householdLocalId;
  String housingType;
  double? rentAmount;
  String rentCurrency;
  bool rentOverdue;
  int rentOverdueMonths;
  bool threatenedWithEviction;
  int roomsCount;
  int residentsCount;
  String condition;
  bool hasElectricity;
  int? electricityHoursPerDay;
  bool hasWater;
  bool hasHeating;
  bool hasSanitation;
  bool hasInternet;
  String? address;
  String? governorate;
  String? city;
  String? neighborhood;
  bool ownedOriginalHomeBefore;
  String? originalHomeStatus;
  bool propertyConfiscated;
  String? confiscationDetails;
  String? notes;
  bool needsSync;

  HousingInfo({
    this.id, this.localId, this.householdLocalId,
    this.housingType = 'rented', this.rentAmount,
    this.rentCurrency = 'SYP',
    this.rentOverdue = false, this.rentOverdueMonths = 0,
    this.threatenedWithEviction = false,
    this.roomsCount = 1, this.residentsCount = 1,
    this.condition = 'acceptable',
    this.hasElectricity = false, this.electricityHoursPerDay,
    this.hasWater = false, this.hasHeating = false,
    this.hasSanitation = false, this.hasInternet = false,
    this.address, this.governorate, this.city, this.neighborhood,
    this.ownedOriginalHomeBefore = false, this.originalHomeStatus,
    this.propertyConfiscated = false, this.confiscationDetails,
    this.notes, this.needsSync = false,
  });

  Map<String, dynamic> toDbMap() => {
    'local_id': localId, 'id': id,
    'household_local_id': householdLocalId,
    'housing_type': housingType, 'rent_amount': rentAmount,
    'rent_currency': rentCurrency,
    'rent_overdue': rentOverdue ? 1 : 0,
    'rent_overdue_months': rentOverdueMonths,
    'threatened_with_eviction': threatenedWithEviction ? 1 : 0,
    'rooms_count': roomsCount, 'residents_count': residentsCount,
    'condition': condition,
    'has_electricity': hasElectricity ? 1 : 0,
    'electricity_hours_per_day': electricityHoursPerDay,
    'has_water': hasWater ? 1 : 0,
    'has_heating': hasHeating ? 1 : 0,
    'has_sanitation': hasSanitation ? 1 : 0,
    'has_internet': hasInternet ? 1 : 0,
    'address': address, 'governorate': governorate,
    'city': city, 'neighborhood': neighborhood,
    'owned_original_home_before': ownedOriginalHomeBefore ? 1 : 0,
    'original_home_status': originalHomeStatus,
    'property_confiscated': propertyConfiscated ? 1 : 0,
    'confiscation_details': confiscationDetails,
    'notes': notes, 'needs_sync': needsSync ? 1 : 0,
  };

  factory HousingInfo.fromDbMap(Map<String, dynamic> m) => HousingInfo(
        id: m['id'] as int?, localId: m['local_id'],
        householdLocalId: m['household_local_id'],
        housingType: m['housing_type'] ?? 'rented',
        rentAmount: (m['rent_amount'] as num?)?.toDouble(),
        rentCurrency: m['rent_currency'] ?? 'SYP',
        rentOverdue: (m['rent_overdue'] ?? 0) == 1,
        rentOverdueMonths: m['rent_overdue_months'] ?? 0,
        threatenedWithEviction: (m['threatened_with_eviction'] ?? 0) == 1,
        roomsCount: m['rooms_count'] ?? 1,
        residentsCount: m['residents_count'] ?? 1,
        condition: m['condition'] ?? 'acceptable',
        hasElectricity: (m['has_electricity'] ?? 0) == 1,
        electricityHoursPerDay: m['electricity_hours_per_day'] as int?,
        hasWater: (m['has_water'] ?? 0) == 1,
        hasHeating: (m['has_heating'] ?? 0) == 1,
        hasSanitation: (m['has_sanitation'] ?? 0) == 1,
        hasInternet: (m['has_internet'] ?? 0) == 1,
        address: m['address'], governorate: m['governorate'],
        city: m['city'], neighborhood: m['neighborhood'],
        ownedOriginalHomeBefore: (m['owned_original_home_before'] ?? 0) == 1,
        originalHomeStatus: m['original_home_status'],
        propertyConfiscated: (m['property_confiscated'] ?? 0) == 1,
        confiscationDetails: m['confiscation_details'],
        notes: m['notes'], needsSync: (m['needs_sync'] ?? 0) == 1,
      );
}

class EducationStatus {
  int? id;
  String? localId;
  String? survivorLocalId;
  String highestLevelBeforeDetention;
  String highestLevelNow;
  bool studiesInterruptedByDetention;
  String? fieldOfStudy;
  String? institution;
  bool isCurrentlyStudying;
  String? currentProgram;
  bool wantsToResume;
  String? obstaclesToEducation;
  String? languagesSpoken;
  bool hasCertificates;
  String? certificatesDetails;
  bool certificatesLost;
  bool needsSync;

  EducationStatus({
    this.id, this.localId, this.survivorLocalId,
    this.highestLevelBeforeDetention = 'illiterate',
    this.highestLevelNow = 'illiterate',
    this.studiesInterruptedByDetention = false,
    this.fieldOfStudy, this.institution,
    this.isCurrentlyStudying = false, this.currentProgram,
    this.wantsToResume = false, this.obstaclesToEducation,
    this.languagesSpoken,
    this.hasCertificates = false, this.certificatesDetails,
    this.certificatesLost = false,
    this.needsSync = false,
  });

  Map<String, dynamic> toDbMap() => {
    'local_id': localId, 'id': id,
    'survivor_local_id': survivorLocalId,
    'highest_level_before_detention': highestLevelBeforeDetention,
    'highest_level_now': highestLevelNow,
    'studies_interrupted_by_detention':
        studiesInterruptedByDetention ? 1 : 0,
    'field_of_study': fieldOfStudy, 'institution': institution,
    'is_currently_studying': isCurrentlyStudying ? 1 : 0,
    'current_program': currentProgram,
    'wants_to_resume': wantsToResume ? 1 : 0,
    'obstacles_to_education': obstaclesToEducation,
    'languages_spoken': languagesSpoken,
    'has_certificates': hasCertificates ? 1 : 0,
    'certificates_details': certificatesDetails,
    'certificates_lost': certificatesLost ? 1 : 0,
    'needs_sync': needsSync ? 1 : 0,
  };

  factory EducationStatus.fromDbMap(Map<String, dynamic> m) => EducationStatus(
        id: m['id'] as int?, localId: m['local_id'],
        survivorLocalId: m['survivor_local_id'],
        highestLevelBeforeDetention:
            m['highest_level_before_detention'] ?? 'illiterate',
        highestLevelNow: m['highest_level_now'] ?? 'illiterate',
        studiesInterruptedByDetention:
            (m['studies_interrupted_by_detention'] ?? 0) == 1,
        fieldOfStudy: m['field_of_study'], institution: m['institution'],
        isCurrentlyStudying: (m['is_currently_studying'] ?? 0) == 1,
        currentProgram: m['current_program'],
        wantsToResume: (m['wants_to_resume'] ?? 0) == 1,
        obstaclesToEducation: m['obstacles_to_education'],
        languagesSpoken: m['languages_spoken'],
        hasCertificates: (m['has_certificates'] ?? 0) == 1,
        certificatesDetails: m['certificates_details'],
        certificatesLost: (m['certificates_lost'] ?? 0) == 1,
        needsSync: (m['needs_sync'] ?? 0) == 1,
      );
}

class EmploymentInfo {
  int? id;
  String? localId;
  String? survivorLocalId;
  String status;
  String? currentOccupation;
  bool sameAsBefore;
  bool unableDueToHealth;
  bool unableDueToLegal;
  double? monthlyIncome;
  String incomeCurrency;
  bool incomeCoversBasicNeeds;
  bool hasSalary;
  bool hasBusinessIncome;
  bool hasPension;
  bool hasRemittance;
  bool hasHumanitarianAid;
  bool hasFamilySupport;
  String? otherIncomeSources;
  int? workHoursPerWeek;
  String? notes;
  bool needsSync;

  EmploymentInfo({
    this.id, this.localId, this.survivorLocalId,
    this.status = 'unemployed_seeking',
    this.currentOccupation,
    this.sameAsBefore = false,
    this.unableDueToHealth = false, this.unableDueToLegal = false,
    this.monthlyIncome, this.incomeCurrency = 'SYP',
    this.incomeCoversBasicNeeds = false,
    this.hasSalary = false, this.hasBusinessIncome = false,
    this.hasPension = false, this.hasRemittance = false,
    this.hasHumanitarianAid = false, this.hasFamilySupport = false,
    this.otherIncomeSources, this.workHoursPerWeek,
    this.notes, this.needsSync = false,
  });

  Map<String, dynamic> toDbMap() => {
    'local_id': localId, 'id': id,
    'survivor_local_id': survivorLocalId,
    'status': status, 'current_occupation': currentOccupation,
    'same_as_before': sameAsBefore ? 1 : 0,
    'unable_due_to_health': unableDueToHealth ? 1 : 0,
    'unable_due_to_legal': unableDueToLegal ? 1 : 0,
    'monthly_income': monthlyIncome, 'income_currency': incomeCurrency,
    'income_covers_basic_needs': incomeCoversBasicNeeds ? 1 : 0,
    'has_salary': hasSalary ? 1 : 0,
    'has_business_income': hasBusinessIncome ? 1 : 0,
    'has_pension': hasPension ? 1 : 0,
    'has_remittance': hasRemittance ? 1 : 0,
    'has_humanitarian_aid': hasHumanitarianAid ? 1 : 0,
    'has_family_support': hasFamilySupport ? 1 : 0,
    'other_income_sources': otherIncomeSources,
    'work_hours_per_week': workHoursPerWeek,
    'notes': notes, 'needs_sync': needsSync ? 1 : 0,
  };

  factory EmploymentInfo.fromDbMap(Map<String, dynamic> m) => EmploymentInfo(
        id: m['id'] as int?, localId: m['local_id'],
        survivorLocalId: m['survivor_local_id'],
        status: m['status'] ?? 'unemployed_seeking',
        currentOccupation: m['current_occupation'],
        sameAsBefore: (m['same_as_before'] ?? 0) == 1,
        unableDueToHealth: (m['unable_due_to_health'] ?? 0) == 1,
        unableDueToLegal: (m['unable_due_to_legal'] ?? 0) == 1,
        monthlyIncome: (m['monthly_income'] as num?)?.toDouble(),
        incomeCurrency: m['income_currency'] ?? 'SYP',
        incomeCoversBasicNeeds: (m['income_covers_basic_needs'] ?? 0) == 1,
        hasSalary: (m['has_salary'] ?? 0) == 1,
        hasBusinessIncome: (m['has_business_income'] ?? 0) == 1,
        hasPension: (m['has_pension'] ?? 0) == 1,
        hasRemittance: (m['has_remittance'] ?? 0) == 1,
        hasHumanitarianAid: (m['has_humanitarian_aid'] ?? 0) == 1,
        hasFamilySupport: (m['has_family_support'] ?? 0) == 1,
        otherIncomeSources: m['other_income_sources'],
        workHoursPerWeek: m['work_hours_per_week'] as int?,
        notes: m['notes'], needsSync: (m['needs_sync'] ?? 0) == 1,
      );
}

class NeedsAssessment {
  int? id;
  String? localId;
  String? householdLocalId;
  String financialAid;
  String foodAid;
  String housingAid;
  String medicalAid;
  String psychologicalSupport;
  String legalAid;
  String educationAid;
  String vocationalTraining;
  String documentsRecovery;
  bool needsIdCard;
  bool needsFamilyBooklet;
  bool needsPassport;
  bool needsBirthCertificate;
  bool needsMarriageCertificate;
  bool needsSecurityClearance;
  String? additionalNeeds;
  String? barriersToAid;
  String assessmentDate;
  bool followUpRequired;
  String? followUpDate;
  String? notes;
  bool needsSync;

  NeedsAssessment({
    this.id, this.localId, this.householdLocalId,
    this.financialAid = 'none', this.foodAid = 'none',
    this.housingAid = 'none', this.medicalAid = 'none',
    this.psychologicalSupport = 'none', this.legalAid = 'none',
    this.educationAid = 'none', this.vocationalTraining = 'none',
    this.documentsRecovery = 'none',
    this.needsIdCard = false, this.needsFamilyBooklet = false,
    this.needsPassport = false, this.needsBirthCertificate = false,
    this.needsMarriageCertificate = false,
    this.needsSecurityClearance = false,
    this.additionalNeeds, this.barriersToAid,
    required this.assessmentDate,
    this.followUpRequired = true, this.followUpDate,
    this.notes, this.needsSync = false,
  });

  Map<String, dynamic> toDbMap() => {
    'local_id': localId, 'id': id,
    'household_local_id': householdLocalId,
    'financial_aid': financialAid, 'food_aid': foodAid,
    'housing_aid': housingAid, 'medical_aid': medicalAid,
    'psychological_support': psychologicalSupport, 'legal_aid': legalAid,
    'education_aid': educationAid,
    'vocational_training': vocationalTraining,
    'documents_recovery': documentsRecovery,
    'needs_id_card': needsIdCard ? 1 : 0,
    'needs_family_booklet': needsFamilyBooklet ? 1 : 0,
    'needs_passport': needsPassport ? 1 : 0,
    'needs_birth_certificate': needsBirthCertificate ? 1 : 0,
    'needs_marriage_certificate': needsMarriageCertificate ? 1 : 0,
    'needs_security_clearance': needsSecurityClearance ? 1 : 0,
    'additional_needs': additionalNeeds,
    'barriers_to_aid': barriersToAid,
    'assessment_date': assessmentDate,
    'follow_up_required': followUpRequired ? 1 : 0,
    'follow_up_date': followUpDate,
    'notes': notes, 'needs_sync': needsSync ? 1 : 0,
  };

  factory NeedsAssessment.fromDbMap(Map<String, dynamic> m) => NeedsAssessment(
        id: m['id'] as int?, localId: m['local_id'],
        householdLocalId: m['household_local_id'],
        financialAid: m['financial_aid'] ?? 'none',
        foodAid: m['food_aid'] ?? 'none',
        housingAid: m['housing_aid'] ?? 'none',
        medicalAid: m['medical_aid'] ?? 'none',
        psychologicalSupport: m['psychological_support'] ?? 'none',
        legalAid: m['legal_aid'] ?? 'none',
        educationAid: m['education_aid'] ?? 'none',
        vocationalTraining: m['vocational_training'] ?? 'none',
        documentsRecovery: m['documents_recovery'] ?? 'none',
        needsIdCard: (m['needs_id_card'] ?? 0) == 1,
        needsFamilyBooklet: (m['needs_family_booklet'] ?? 0) == 1,
        needsPassport: (m['needs_passport'] ?? 0) == 1,
        needsBirthCertificate: (m['needs_birth_certificate'] ?? 0) == 1,
        needsMarriageCertificate: (m['needs_marriage_certificate'] ?? 0) == 1,
        needsSecurityClearance: (m['needs_security_clearance'] ?? 0) == 1,
        additionalNeeds: m['additional_needs'],
        barriersToAid: m['barriers_to_aid'],
        assessmentDate: m['assessment_date'] ?? '',
        followUpRequired: (m['follow_up_required'] ?? 1) == 1,
        followUpDate: m['follow_up_date'],
        notes: m['notes'], needsSync: (m['needs_sync'] ?? 0) == 1,
      );
}

class HealthAccess {
  int? id;
  String? localId;
  String? householdLocalId;
  bool hasHealthInsurance;
  String? insuranceType;
  bool accessToPrimaryCare;
  bool accessToSpecializedCare;
  double? distanceToHealthFacilityKm;
  String? chronicIllnessesInFamily;
  int familyMembersWithDisability;
  bool psychologicalSupportReceived;
  String? psychologicalSupportProvider;
  bool medicationsUnaffordable;
  String? unmetMedicalNeeds;
  String foodSecurity;
  int mealsPerDay;
  String? notes;
  bool needsSync;

  HealthAccess({
    this.id, this.localId, this.householdLocalId,
    this.hasHealthInsurance = false, this.insuranceType,
    this.accessToPrimaryCare = false, this.accessToSpecializedCare = false,
    this.distanceToHealthFacilityKm,
    this.chronicIllnessesInFamily,
    this.familyMembersWithDisability = 0,
    this.psychologicalSupportReceived = false,
    this.psychologicalSupportProvider,
    this.medicationsUnaffordable = false, this.unmetMedicalNeeds,
    this.foodSecurity = 'moderate', this.mealsPerDay = 3,
    this.notes, this.needsSync = false,
  });

  Map<String, dynamic> toDbMap() => {
    'local_id': localId, 'id': id,
    'household_local_id': householdLocalId,
    'has_health_insurance': hasHealthInsurance ? 1 : 0,
    'insurance_type': insuranceType,
    'access_to_primary_care': accessToPrimaryCare ? 1 : 0,
    'access_to_specialized_care': accessToSpecializedCare ? 1 : 0,
    'distance_to_health_facility_km': distanceToHealthFacilityKm,
    'chronic_illnesses_in_family': chronicIllnessesInFamily,
    'family_members_with_disability': familyMembersWithDisability,
    'psychological_support_received': psychologicalSupportReceived ? 1 : 0,
    'psychological_support_provider': psychologicalSupportProvider,
    'medications_unaffordable': medicationsUnaffordable ? 1 : 0,
    'unmet_medical_needs': unmetMedicalNeeds,
    'food_security': foodSecurity, 'meals_per_day': mealsPerDay,
    'notes': notes, 'needs_sync': needsSync ? 1 : 0,
  };

  factory HealthAccess.fromDbMap(Map<String, dynamic> m) => HealthAccess(
        id: m['id'] as int?, localId: m['local_id'],
        householdLocalId: m['household_local_id'],
        hasHealthInsurance: (m['has_health_insurance'] ?? 0) == 1,
        insuranceType: m['insurance_type'],
        accessToPrimaryCare: (m['access_to_primary_care'] ?? 0) == 1,
        accessToSpecializedCare: (m['access_to_specialized_care'] ?? 0) == 1,
        distanceToHealthFacilityKm:
            (m['distance_to_health_facility_km'] as num?)?.toDouble(),
        chronicIllnessesInFamily: m['chronic_illnesses_in_family'],
        familyMembersWithDisability: m['family_members_with_disability'] ?? 0,
        psychologicalSupportReceived:
            (m['psychological_support_received'] ?? 0) == 1,
        psychologicalSupportProvider: m['psychological_support_provider'],
        medicationsUnaffordable: (m['medications_unaffordable'] ?? 0) == 1,
        unmetMedicalNeeds: m['unmet_medical_needs'],
        foodSecurity: m['food_security'] ?? 'moderate',
        mealsPerDay: m['meals_per_day'] ?? 3,
        notes: m['notes'], needsSync: (m['needs_sync'] ?? 0) == 1,
      );
}
