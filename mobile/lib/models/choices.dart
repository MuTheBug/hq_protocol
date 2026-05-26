/// قوائم الخيارات المرجعية - تأتي من الـAPI وتُكاش محلياً
class Choice {
  final String value;
  final String label;
  Choice({required this.value, required this.label});

  factory Choice.fromJson(Map<String, dynamic> j) => Choice(
        value: j['value'] ?? '',
        label: j['label'] ?? '',
      );
}

class Facility {
  final int id;
  final String nameAr;
  final String branchNumber;
  final String parentEntity;
  final String parentEntityDisplay;
  final String governorate;

  Facility({
    required this.id,
    required this.nameAr,
    required this.branchNumber,
    required this.parentEntity,
    required this.parentEntityDisplay,
    required this.governorate,
  });

  factory Facility.fromJson(Map<String, dynamic> j) => Facility(
        id: j['id'] as int,
        nameAr: j['name_ar'] ?? '',
        branchNumber: j['branch_number'] ?? '',
        parentEntity: j['parent_entity'] ?? '',
        parentEntityDisplay: j['parent_entity_display'] ?? '',
        governorate: j['governorate'] ?? '',
      );

  String get displayName => branchNumber.isEmpty
      ? nameAr
      : '$nameAr (فرع $branchNumber)';
}

class ReferenceData {
  final List<Facility> facilities;
  final Map<String, List<Choice>> choices;
  final Map<String, dynamic> syriaGeo;

  ReferenceData({
    required this.facilities,
    required this.choices,
    required this.syriaGeo,
  });

  factory ReferenceData.fromJson(Map<String, dynamic> j) {
    final choicesMap = <String, List<Choice>>{};
    final rawChoices = j['choices'] as Map<String, dynamic>? ?? {};
    rawChoices.forEach((key, value) {
      choicesMap[key] = (value as List)
          .map((e) => Choice.fromJson(e as Map<String, dynamic>))
          .toList();
    });
    return ReferenceData(
      facilities: (j['facilities'] as List? ?? [])
          .map((f) => Facility.fromJson(f as Map<String, dynamic>))
          .toList(),
      choices: choicesMap,
      syriaGeo: j['syria_geo'] as Map<String, dynamic>? ?? {},
    );
  }

  List<Choice> get governorates => choices['syrian_governorates'] ?? [];
  List<Choice> get genders => choices['genders'] ?? [];
  List<Choice> get countries => choices['countries'] ?? [];
  List<Choice> get occupations => choices['occupations'] ?? [];
  List<Choice> get politicalActivities => choices['political_activities'] ?? [];
  List<Choice> get maritalStatuses => choices['marital_statuses'] ?? [];
  List<Choice> get fileClassifications => choices['file_classifications'] ?? [];
}
