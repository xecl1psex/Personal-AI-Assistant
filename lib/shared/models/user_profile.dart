/// User profile model (local, private data).
class UserProfile {
  const UserProfile({
    this.id,
    this.name = '',
    this.bio = '',
    this.avatarPath,
    this.currency = 'RUB',
    this.languageCode = 'ru',
    this.goalOfDay = '',
    this.birthday,
    this.createdAt,
  });

  /// Database row id (null for unsaved items).
  final int? id;

  /// Display name.
  final String name;

  /// Short self-description used as AI context.
  final String bio;

  /// Local filesystem path to the avatar image (nullable).
  final String? avatarPath;

  /// Preferred currency code (ISO 4217), e.g. 'RUB', 'USD'.
  final String currency;

  /// UI language, e.g. 'ru', 'en'.
  final String languageCode;

  /// Main personal goal shown on the dashboard.
  final String goalOfDay;

  /// Optional birthday.
  final DateTime? birthday;

  /// Creation timestamp.
  final DateTime? createdAt;

  bool get isEmpty => name.isEmpty && bio.isEmpty;

  UserProfile copyWith({
    int? id,
    String? name,
    String? bio,
    String? avatarPath,
    String? currency,
    String? languageCode,
    String? goalOfDay,
    DateTime? birthday,
    DateTime? createdAt,
  }) {
    return UserProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      bio: bio ?? this.bio,
      avatarPath: avatarPath ?? this.avatarPath,
      currency: currency ?? this.currency,
      languageCode: languageCode ?? this.languageCode,
      goalOfDay: goalOfDay ?? this.goalOfDay,
      birthday: birthday ?? this.birthday,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, Object?> toMap() {
    return <String, Object?>{
      'id': id,
      'name': name,
      'bio': bio,
      'avatar_path': avatarPath,
      'currency': currency,
      'language_code': languageCode,
      'goal_of_day': goalOfDay,
      'birthday': birthday?.toIso8601String(),
      'created_at': createdAt?.toIso8601String(),
    };
  }

  factory UserProfile.fromMap(Map<String, Object?> map) {
    return UserProfile(
      id: map['id'] as int?,
      name: (map['name'] as String?) ?? '',
      bio: (map['bio'] as String?) ?? '',
      avatarPath: map['avatar_path'] as String?,
      currency: (map['currency'] as String?) ?? 'RUB',
      languageCode: (map['language_code'] as String?) ?? 'ru',
      goalOfDay: (map['goal_of_day'] as String?) ?? '',
      birthday: map['birthday'] is String
          ? DateTime.tryParse(map['birthday'] as String)
          : null,
      createdAt: map['created_at'] is String
          ? DateTime.tryParse(map['created_at'] as String)
          : null,
    );
  }

  Map<String, Object?> toJson() => <String, Object?>{
        'id': id,
        'name': name,
        'bio': bio,
        'avatar_path': avatarPath,
        'currency': currency,
        'language_code': languageCode,
        'goal_of_day': goalOfDay,
        'birthday': birthday?.toIso8601String(),
        'created_at': createdAt?.toIso8601String(),
      };

  factory UserProfile.fromJson(Map<String, Object?> json) =>
      UserProfile.fromMap(json);

  @override
  String toString() => 'UserProfile(name: $name, currency: $currency)';
}
