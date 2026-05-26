class User {
  final int id;
  final String username;
  final String fullNameAr;
  final String role;
  final String roleDisplay;
  final bool canDocument;
  final bool canReview;
  final bool isSuperuser;

  User({
    required this.id,
    required this.username,
    required this.fullNameAr,
    required this.role,
    required this.roleDisplay,
    required this.canDocument,
    required this.canReview,
    required this.isSuperuser,
  });

  factory User.fromJson(Map<String, dynamic> j) => User(
        id: j['id'] as int,
        username: j['username'] as String,
        fullNameAr: j['full_name_ar'] ?? '',
        role: j['role'] ?? '',
        roleDisplay: j['role_display'] ?? '',
        canDocument: j['can_document'] ?? false,
        canReview: j['can_review'] ?? false,
        isSuperuser: j['is_superuser'] ?? false,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'username': username,
        'full_name_ar': fullNameAr,
        'role': role,
        'role_display': roleDisplay,
        'can_document': canDocument,
        'can_review': canReview,
        'is_superuser': isSuperuser,
      };
}
