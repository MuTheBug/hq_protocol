/// نماذج الكيانات المرتبطة بالناجي - مطابقة للـ Django backend.
/// كلها قابلة للتسلسل من/إلى JSON و Map (SQLite).

class DetentionEvent {
  int? id;
  String? localId;
  String? survivorLocalId; // ربط محلي قبل المزامنة
  int? survivorId;
  String detentionDate;
  bool dateApproximate;
  String detentionLocation;
  String? governorate;
  String arrestingEntity;
  String? arrestingPersonnelDetails;
  String? reasonStated;
  String? circumstances;
  String? witnessesToArrest;
  bool familyNotified;
  String? notes;
  bool needsSync;

  DetentionEvent({
    this.id,
    this.localId,
    this.survivorLocalId,
    this.survivorId,
    required this.detentionDate,
    this.dateApproximate = false,
    required this.detentionLocation,
    this.governorate,
    required this.arrestingEntity,
    this.arrestingPersonnelDetails,
    this.reasonStated,
    this.circumstances,
    this.witnessesToArrest,
    this.familyNotified = false,
    this.notes,
    this.needsSync = false,
  });

  factory DetentionEvent.fromJson(Map<String, dynamic> j) => DetentionEvent(
        id: j['id'],
        survivorId: j['survivor_id'],
        detentionDate: j['detention_date'] ?? '',
        dateApproximate: j['date_approximate'] ?? false,
        detentionLocation: j['detention_location'] ?? '',
        governorate: j['governorate'],
        arrestingEntity: j['arresting_entity'] ?? '',
        arrestingPersonnelDetails: j['arresting_personnel_details'],
        reasonStated: j['reason_stated'],
        circumstances: j['circumstances'],
        witnessesToArrest: j['witnesses_to_arrest'],
        familyNotified: j['family_notified'] ?? false,
        notes: j['notes'],
      );

  Map<String, dynamic> toApiJson() {
    final m = <String, dynamic>{
      'detention_date': detentionDate,
      'date_approximate': dateApproximate,
      'detention_location': detentionLocation,
      'arresting_entity': arrestingEntity,
      'family_notified': familyNotified,
    };
    void put(String k, dynamic v) {
      if (v != null && v != '') m[k] = v;
    }
    put('governorate', governorate);
    put('arresting_personnel_details', arrestingPersonnelDetails);
    put('reason_stated', reasonStated);
    put('circumstances', circumstances);
    put('witnesses_to_arrest', witnessesToArrest);
    put('notes', notes);
    if (localId != null) m['_local_id'] = localId;
    return m;
  }

  Map<String, dynamic> toDbMap() => {
        'local_id': localId,
        'id': id,
        'survivor_local_id': survivorLocalId,
        'survivor_id': survivorId,
        'detention_date': detentionDate,
        'date_approximate': dateApproximate ? 1 : 0,
        'detention_location': detentionLocation,
        'governorate': governorate,
        'arresting_entity': arrestingEntity,
        'arresting_personnel_details': arrestingPersonnelDetails,
        'reason_stated': reasonStated,
        'circumstances': circumstances,
        'witnesses_to_arrest': witnessesToArrest,
        'family_notified': familyNotified ? 1 : 0,
        'notes': notes,
        'needs_sync': needsSync ? 1 : 0,
      };

  factory DetentionEvent.fromDbMap(Map<String, dynamic> m) => DetentionEvent(
        id: m['id'] as int?,
        localId: m['local_id'],
        survivorLocalId: m['survivor_local_id'],
        survivorId: m['survivor_id'] as int?,
        detentionDate: m['detention_date'] ?? '',
        dateApproximate: (m['date_approximate'] ?? 0) == 1,
        detentionLocation: m['detention_location'] ?? '',
        governorate: m['governorate'],
        arrestingEntity: m['arresting_entity'] ?? '',
        arrestingPersonnelDetails: m['arresting_personnel_details'],
        reasonStated: m['reason_stated'],
        circumstances: m['circumstances'],
        witnessesToArrest: m['witnesses_to_arrest'],
        familyNotified: (m['family_notified'] ?? 0) == 1,
        notes: m['notes'],
        needsSync: (m['needs_sync'] ?? 0) == 1,
      );
}

class DetentionPeriod {
  int? id;
  String? localId;
  String? survivorLocalId;
  int? survivorId;
  int? facilityId;
  String? facilityName;
  String fromDate;
  String? toDate;
  int orderIndex;
  String? cellDescription;
  int? cellmatesCount;
  String? tortureDescription;
  bool sexualViolenceReported;
  String? notes;
  List<int> tortureMethodIds;
  bool needsSync;

  DetentionPeriod({
    this.id, this.localId, this.survivorLocalId, this.survivorId,
    this.facilityId, this.facilityName,
    required this.fromDate, this.toDate,
    this.orderIndex = 1,
    this.cellDescription, this.cellmatesCount,
    this.tortureDescription,
    this.sexualViolenceReported = false,
    this.notes,
    this.tortureMethodIds = const [],
    this.needsSync = false,
  });

  factory DetentionPeriod.fromJson(Map<String, dynamic> j) => DetentionPeriod(
        id: j['id'],
        survivorId: j['survivor_id'],
        facilityId: j['facility_id'],
        facilityName: j['facility_name'],
        fromDate: j['from_date'] ?? '',
        toDate: j['to_date'],
        orderIndex: j['order_index'] ?? 1,
        cellDescription: j['cell_description'],
        cellmatesCount: j['cellmates_count'],
        tortureDescription: j['torture_description'],
        sexualViolenceReported: j['sexual_violence_reported'] ?? false,
        tortureMethodIds:
            (j['torture_method_ids'] as List?)?.cast<int>() ?? [],
      );

  Map<String, dynamic> toApiJson() {
    final m = <String, dynamic>{
      'facility_id': facilityId,
      'from_date': fromDate,
      'order_index': orderIndex,
      'sexual_violence_reported': sexualViolenceReported,
      'torture_method_ids': tortureMethodIds,
    };
    void put(String k, dynamic v) { if (v != null && v != '') m[k] = v; }
    put('to_date', toDate);
    put('cell_description', cellDescription);
    put('cellmates_count', cellmatesCount);
    put('torture_description', tortureDescription);
    put('notes', notes);
    if (localId != null) m['_local_id'] = localId;
    return m;
  }

  Map<String, dynamic> toDbMap() => {
        'local_id': localId, 'id': id,
        'survivor_local_id': survivorLocalId, 'survivor_id': survivorId,
        'facility_id': facilityId, 'facility_name': facilityName,
        'from_date': fromDate, 'to_date': toDate,
        'order_index': orderIndex,
        'cell_description': cellDescription, 'cellmates_count': cellmatesCount,
        'torture_description': tortureDescription,
        'sexual_violence_reported': sexualViolenceReported ? 1 : 0,
        'notes': notes,
        'torture_method_ids': tortureMethodIds.join(','),
        'needs_sync': needsSync ? 1 : 0,
      };

  factory DetentionPeriod.fromDbMap(Map<String, dynamic> m) => DetentionPeriod(
        id: m['id'] as int?, localId: m['local_id'],
        survivorLocalId: m['survivor_local_id'],
        survivorId: m['survivor_id'] as int?,
        facilityId: m['facility_id'] as int?, facilityName: m['facility_name'],
        fromDate: m['from_date'] ?? '', toDate: m['to_date'],
        orderIndex: m['order_index'] ?? 1,
        cellDescription: m['cell_description'],
        cellmatesCount: m['cellmates_count'] as int?,
        tortureDescription: m['torture_description'],
        sexualViolenceReported: (m['sexual_violence_reported'] ?? 0) == 1,
        notes: m['notes'],
        tortureMethodIds: ((m['torture_method_ids'] ?? '') as String)
            .split(',').where((s) => s.isNotEmpty)
            .map(int.parse).toList(),
        needsSync: (m['needs_sync'] ?? 0) == 1,
      );
}

class ReleaseEvent {
  int? id;
  String? localId;
  String? survivorLocalId;
  int? survivorId;
  String releaseDate;
  String releaseType;
  String? releaseLocation;
  String? bribeAmount;
  String? conditions;
  String circumstances;
  bool needsSync;

  ReleaseEvent({
    this.id, this.localId, this.survivorLocalId, this.survivorId,
    required this.releaseDate, this.releaseType = 'unknown',
    this.releaseLocation, this.bribeAmount, this.conditions,
    this.circumstances = '', this.needsSync = false,
  });

  factory ReleaseEvent.fromJson(Map<String, dynamic> j) => ReleaseEvent(
        id: j['id'], survivorId: j['survivor_id'],
        releaseDate: j['release_date'] ?? '',
        releaseType: j['release_type'] ?? 'unknown',
        releaseLocation: j['release_location'],
        bribeAmount: j['bribe_amount'],
        conditions: j['conditions'],
        circumstances: j['circumstances'] ?? '',
      );

  Map<String, dynamic> toApiJson() {
    final m = {
      'release_date': releaseDate, 'release_type': releaseType,
      'circumstances': circumstances,
    };
    if (releaseLocation?.isNotEmpty == true) m['release_location'] = releaseLocation!;
    if (bribeAmount?.isNotEmpty == true) m['bribe_amount'] = bribeAmount!;
    if (conditions?.isNotEmpty == true) m['conditions'] = conditions!;
    if (localId != null) m['_local_id'] = localId!;
    return m;
  }

  Map<String, dynamic> toDbMap() => {
        'local_id': localId, 'id': id,
        'survivor_local_id': survivorLocalId, 'survivor_id': survivorId,
        'release_date': releaseDate, 'release_type': releaseType,
        'release_location': releaseLocation, 'bribe_amount': bribeAmount,
        'conditions': conditions, 'circumstances': circumstances,
        'needs_sync': needsSync ? 1 : 0,
      };

  factory ReleaseEvent.fromDbMap(Map<String, dynamic> m) => ReleaseEvent(
        id: m['id'] as int?, localId: m['local_id'],
        survivorLocalId: m['survivor_local_id'],
        survivorId: m['survivor_id'] as int?,
        releaseDate: m['release_date'] ?? '',
        releaseType: m['release_type'] ?? 'unknown',
        releaseLocation: m['release_location'],
        bribeAmount: m['bribe_amount'],
        conditions: m['conditions'],
        circumstances: m['circumstances'] ?? '',
        needsSync: (m['needs_sync'] ?? 0) == 1,
      );
}

class InformedConsent {
  int? id;
  String? localId;
  String? survivorLocalId;
  int? survivorId;
  bool consentDocumented;
  String? consentDate;
  String? consentWitness;
  bool shareWithIiim;
  bool shareWithCoi;
  bool shareWithIcc;
  bool shareWithUniversalJurisdiction;
  bool shareWithPartnerOrgs;
  bool shareWithMedia;
  bool sharePublicly;
  bool anonymizeName;
  bool anonymizePhoto;
  bool anonymizeLocation;
  bool anonymizeFamilyDetails;
  bool withdrawalRightExplained;
  bool confidentialityLimitsExplained;
  bool intendedUsesExplained;
  bool consentWithdrawn;
  bool needsSync;

  InformedConsent({
    this.id, this.localId, this.survivorLocalId, this.survivorId,
    this.consentDocumented = false, this.consentDate, this.consentWitness,
    this.shareWithIiim = false, this.shareWithCoi = false, this.shareWithIcc = false,
    this.shareWithUniversalJurisdiction = false, this.shareWithPartnerOrgs = false,
    this.shareWithMedia = false, this.sharePublicly = false,
    this.anonymizeName = false, this.anonymizePhoto = false,
    this.anonymizeLocation = false, this.anonymizeFamilyDetails = false,
    this.withdrawalRightExplained = false,
    this.confidentialityLimitsExplained = false,
    this.intendedUsesExplained = false, this.consentWithdrawn = false,
    this.needsSync = false,
  });

  factory InformedConsent.fromJson(Map<String, dynamic> j) => InformedConsent(
        id: j['id'], survivorId: j['survivor_id'],
        consentDocumented: j['consent_documented'] ?? false,
        consentDate: j['consent_date'], consentWitness: j['consent_witness'],
        shareWithIiim: j['share_with_iiim'] ?? false,
        shareWithCoi: j['share_with_coi'] ?? false,
        shareWithIcc: j['share_with_icc'] ?? false,
        shareWithUniversalJurisdiction:
            j['share_with_universal_jurisdiction'] ?? false,
        shareWithPartnerOrgs: j['share_with_partner_orgs'] ?? false,
        shareWithMedia: j['share_with_media'] ?? false,
        sharePublicly: j['share_publicly'] ?? false,
        anonymizeName: j['anonymize_name'] ?? false,
        anonymizePhoto: j['anonymize_photo'] ?? false,
        anonymizeLocation: j['anonymize_location'] ?? false,
        anonymizeFamilyDetails: j['anonymize_family_details'] ?? false,
        withdrawalRightExplained: j['withdrawal_right_explained'] ?? false,
        confidentialityLimitsExplained:
            j['confidentiality_limits_explained'] ?? false,
        intendedUsesExplained: j['intended_uses_explained'] ?? false,
        consentWithdrawn: j['consent_withdrawn'] ?? false,
      );

  bool get isFullyCompliant =>
      consentDocumented &&
      withdrawalRightExplained &&
      confidentialityLimitsExplained &&
      intendedUsesExplained &&
      !consentWithdrawn;

  Map<String, dynamic> toApiJson() {
    final m = <String, dynamic>{
      'consent_documented': consentDocumented,
      'share_with_iiim': shareWithIiim, 'share_with_coi': shareWithCoi,
      'share_with_icc': shareWithIcc,
      'share_with_universal_jurisdiction': shareWithUniversalJurisdiction,
      'share_with_partner_orgs': shareWithPartnerOrgs,
      'share_with_media': shareWithMedia, 'share_publicly': sharePublicly,
      'anonymize_name': anonymizeName, 'anonymize_photo': anonymizePhoto,
      'anonymize_location': anonymizeLocation,
      'anonymize_family_details': anonymizeFamilyDetails,
      'withdrawal_right_explained': withdrawalRightExplained,
      'confidentiality_limits_explained': confidentialityLimitsExplained,
      'intended_uses_explained': intendedUsesExplained,
      'consent_withdrawn': consentWithdrawn,
    };
    if (consentDate?.isNotEmpty == true) m['consent_date'] = consentDate;
    if (consentWitness?.isNotEmpty == true) m['consent_witness'] = consentWitness;
    if (localId != null) m['_local_id'] = localId;
    return m;
  }

  Map<String, dynamic> toDbMap() => {
        'local_id': localId, 'id': id,
        'survivor_local_id': survivorLocalId, 'survivor_id': survivorId,
        'consent_documented': consentDocumented ? 1 : 0,
        'consent_date': consentDate, 'consent_witness': consentWitness,
        'share_with_iiim': shareWithIiim ? 1 : 0,
        'share_with_coi': shareWithCoi ? 1 : 0,
        'share_with_icc': shareWithIcc ? 1 : 0,
        'share_with_universal_jurisdiction':
            shareWithUniversalJurisdiction ? 1 : 0,
        'share_with_partner_orgs': shareWithPartnerOrgs ? 1 : 0,
        'share_with_media': shareWithMedia ? 1 : 0,
        'share_publicly': sharePublicly ? 1 : 0,
        'anonymize_name': anonymizeName ? 1 : 0,
        'anonymize_photo': anonymizePhoto ? 1 : 0,
        'anonymize_location': anonymizeLocation ? 1 : 0,
        'anonymize_family_details': anonymizeFamilyDetails ? 1 : 0,
        'withdrawal_right_explained': withdrawalRightExplained ? 1 : 0,
        'confidentiality_limits_explained':
            confidentialityLimitsExplained ? 1 : 0,
        'intended_uses_explained': intendedUsesExplained ? 1 : 0,
        'consent_withdrawn': consentWithdrawn ? 1 : 0,
        'needs_sync': needsSync ? 1 : 0,
      };

  factory InformedConsent.fromDbMap(Map<String, dynamic> m) => InformedConsent(
        id: m['id'] as int?, localId: m['local_id'],
        survivorLocalId: m['survivor_local_id'],
        survivorId: m['survivor_id'] as int?,
        consentDocumented: (m['consent_documented'] ?? 0) == 1,
        consentDate: m['consent_date'], consentWitness: m['consent_witness'],
        shareWithIiim: (m['share_with_iiim'] ?? 0) == 1,
        shareWithCoi: (m['share_with_coi'] ?? 0) == 1,
        shareWithIcc: (m['share_with_icc'] ?? 0) == 1,
        shareWithUniversalJurisdiction:
            (m['share_with_universal_jurisdiction'] ?? 0) == 1,
        shareWithPartnerOrgs: (m['share_with_partner_orgs'] ?? 0) == 1,
        shareWithMedia: (m['share_with_media'] ?? 0) == 1,
        sharePublicly: (m['share_publicly'] ?? 0) == 1,
        anonymizeName: (m['anonymize_name'] ?? 0) == 1,
        anonymizePhoto: (m['anonymize_photo'] ?? 0) == 1,
        anonymizeLocation: (m['anonymize_location'] ?? 0) == 1,
        anonymizeFamilyDetails: (m['anonymize_family_details'] ?? 0) == 1,
        withdrawalRightExplained: (m['withdrawal_right_explained'] ?? 0) == 1,
        confidentialityLimitsExplained:
            (m['confidentiality_limits_explained'] ?? 0) == 1,
        intendedUsesExplained: (m['intended_uses_explained'] ?? 0) == 1,
        consentWithdrawn: (m['consent_withdrawn'] ?? 0) == 1,
        needsSync: (m['needs_sync'] ?? 0) == 1,
      );
}

class Witness {
  int? id;
  String? localId;
  String? survivorLocalId;
  int? survivorId;
  String witnessName;
  String? witnessPhone;
  String? witnessCurrentLocation;
  int? facilityId;
  String? facilityName;
  String periodFrom;
  String? periodTo;
  String? cellNumber;
  String howRecognized;
  String? distinguishingDetails;
  String? specificIncidents;
  String relationshipBefore;
  bool isIndependent;
  bool metAfterRelease;
  bool consentToUseTestimony;
  bool declarationSigned;
  String? declarationDate;
  String fullTestimony;
  bool needsSync;

  Witness({
    this.id, this.localId, this.survivorLocalId, this.survivorId,
    required this.witnessName, this.witnessPhone, this.witnessCurrentLocation,
    this.facilityId, this.facilityName,
    required this.periodFrom, this.periodTo, this.cellNumber,
    required this.howRecognized,
    this.distinguishingDetails, this.specificIncidents,
    this.relationshipBefore = 'stranger',
    this.isIndependent = false, this.metAfterRelease = false,
    this.consentToUseTestimony = false, this.declarationSigned = false,
    this.declarationDate,
    this.fullTestimony = '', this.needsSync = false,
  });

  factory Witness.fromJson(Map<String, dynamic> j) => Witness(
        id: j['id'], survivorId: j['survivor_id'],
        witnessName: j['witness_name'] ?? '',
        witnessPhone: j['witness_phone'],
        witnessCurrentLocation: j['witness_current_location'],
        facilityId: j['facility_witnessed_at_id'],
        periodFrom: j['period_from'] ?? '', periodTo: j['period_to'],
        cellNumber: j['cell_number'],
        howRecognized: j['how_recognized'] ?? '',
        distinguishingDetails: j['distinguishing_details'],
        specificIncidents: j['specific_incidents'],
        relationshipBefore: j['relationship_before'] ?? 'stranger',
        isIndependent: j['is_independent'] ?? false,
        metAfterRelease: j['met_after_release'] ?? false,
        consentToUseTestimony: j['consent_to_use_testimony'] ?? false,
        declarationSigned: j['declaration_signed'] ?? false,
        declarationDate: j['declaration_date'],
        fullTestimony: j['full_testimony'] ?? '',
      );

  Map<String, dynamic> toApiJson() {
    final m = <String, dynamic>{
      'witness_name': witnessName,
      'facility_witnessed_at_id': facilityId,
      'period_from': periodFrom,
      'how_recognized': howRecognized,
      'relationship_before': relationshipBefore,
      'is_independent': isIndependent,
      'met_after_release': metAfterRelease,
      'consent_to_use_testimony': consentToUseTestimony,
      'declaration_signed': declarationSigned,
      'full_testimony': fullTestimony,
    };
    void put(String k, dynamic v) { if (v != null && v != '') m[k] = v; }
    put('witness_phone', witnessPhone);
    put('witness_current_location', witnessCurrentLocation);
    put('period_to', periodTo);
    put('cell_number', cellNumber);
    put('distinguishing_details', distinguishingDetails);
    put('specific_incidents', specificIncidents);
    put('declaration_date', declarationDate);
    if (localId != null) m['_local_id'] = localId;
    return m;
  }

  Map<String, dynamic> toDbMap() => {
        'local_id': localId, 'id': id,
        'survivor_local_id': survivorLocalId, 'survivor_id': survivorId,
        'witness_name': witnessName, 'witness_phone': witnessPhone,
        'witness_current_location': witnessCurrentLocation,
        'facility_id': facilityId, 'facility_name': facilityName,
        'period_from': periodFrom, 'period_to': periodTo,
        'cell_number': cellNumber,
        'how_recognized': howRecognized,
        'distinguishing_details': distinguishingDetails,
        'specific_incidents': specificIncidents,
        'relationship_before': relationshipBefore,
        'is_independent': isIndependent ? 1 : 0,
        'met_after_release': metAfterRelease ? 1 : 0,
        'consent_to_use_testimony': consentToUseTestimony ? 1 : 0,
        'declaration_signed': declarationSigned ? 1 : 0,
        'declaration_date': declarationDate,
        'full_testimony': fullTestimony,
        'needs_sync': needsSync ? 1 : 0,
      };

  factory Witness.fromDbMap(Map<String, dynamic> m) => Witness(
        id: m['id'] as int?, localId: m['local_id'],
        survivorLocalId: m['survivor_local_id'],
        survivorId: m['survivor_id'] as int?,
        witnessName: m['witness_name'] ?? '',
        witnessPhone: m['witness_phone'],
        witnessCurrentLocation: m['witness_current_location'],
        facilityId: m['facility_id'] as int?, facilityName: m['facility_name'],
        periodFrom: m['period_from'] ?? '', periodTo: m['period_to'],
        cellNumber: m['cell_number'],
        howRecognized: m['how_recognized'] ?? '',
        distinguishingDetails: m['distinguishing_details'],
        specificIncidents: m['specific_incidents'],
        relationshipBefore: m['relationship_before'] ?? 'stranger',
        isIndependent: (m['is_independent'] ?? 0) == 1,
        metAfterRelease: (m['met_after_release'] ?? 0) == 1,
        consentToUseTestimony: (m['consent_to_use_testimony'] ?? 0) == 1,
        declarationSigned: (m['declaration_signed'] ?? 0) == 1,
        declarationDate: m['declaration_date'],
        fullTestimony: m['full_testimony'] ?? '',
        needsSync: (m['needs_sync'] ?? 0) == 1,
      );
}

class SurvivorNote {
  int? id;
  String? localId;
  String? survivorLocalId;
  int? survivorId;
  String noteType;
  String? title;
  String content;
  bool isPinned;
  bool isConfidential;
  String? authorUsername;
  String? createdAt;
  bool needsSync;

  SurvivorNote({
    this.id, this.localId, this.survivorLocalId, this.survivorId,
    this.noteType = 'general', this.title, required this.content,
    this.isPinned = false, this.isConfidential = false,
    this.authorUsername, this.createdAt, this.needsSync = false,
  });

  factory SurvivorNote.fromJson(Map<String, dynamic> j) => SurvivorNote(
        id: j['id'], survivorId: j['survivor_id'],
        noteType: j['note_type'] ?? 'general',
        title: j['title'], content: j['content'] ?? '',
        isPinned: j['is_pinned'] ?? false,
        isConfidential: j['is_confidential'] ?? false,
        authorUsername: j['author_username'], createdAt: j['created_at'],
      );

  Map<String, dynamic> toApiJson() {
    final m = <String, dynamic>{
      'note_type': noteType, 'content': content,
      'is_pinned': isPinned, 'is_confidential': isConfidential,
    };
    if (title?.isNotEmpty == true) m['title'] = title;
    if (localId != null) m['_local_id'] = localId;
    return m;
  }

  Map<String, dynamic> toDbMap() => {
        'local_id': localId, 'id': id,
        'survivor_local_id': survivorLocalId, 'survivor_id': survivorId,
        'note_type': noteType, 'title': title, 'content': content,
        'is_pinned': isPinned ? 1 : 0,
        'is_confidential': isConfidential ? 1 : 0,
        'author_username': authorUsername, 'created_at': createdAt,
        'needs_sync': needsSync ? 1 : 0,
      };

  factory SurvivorNote.fromDbMap(Map<String, dynamic> m) => SurvivorNote(
        id: m['id'] as int?, localId: m['local_id'],
        survivorLocalId: m['survivor_local_id'],
        survivorId: m['survivor_id'] as int?,
        noteType: m['note_type'] ?? 'general',
        title: m['title'], content: m['content'] ?? '',
        isPinned: (m['is_pinned'] ?? 0) == 1,
        isConfidential: (m['is_confidential'] ?? 0) == 1,
        authorUsername: m['author_username'], createdAt: m['created_at'],
        needsSync: (m['needs_sync'] ?? 0) == 1,
      );
}
