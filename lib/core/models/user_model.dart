import 'mission_model.dart';

enum UserRole {
  teacher('teacher'),
  student('student');

  const UserRole(this.wireName);

  final String wireName;

  static UserRole fromWireName(String value) {
    return values.firstWhere(
      (role) => role.wireName == value,
      orElse: () => throw FormatException('Rol no compatible: $value'),
    );
  }
}

class UserModel {
  const UserModel({
    required this.id,
    required this.username,
    required this.displayName,
    required this.role,
  });

  final String id;
  final String username;
  final String displayName;
  final UserRole role;

  factory UserModel.fromJson(Map<String, Object?> json) => UserModel(
    id: json.string('id'),
    username: json.string('username'),
    displayName: json.string('displayName'),
    role: UserRole.fromWireName(json.string('role')),
  );

  Map<String, Object?> toJson() => {
    'id': id,
    'username': username,
    'displayName': displayName,
    'role': role.wireName,
  };
}

class AuthSnapshot {
  const AuthSnapshot({required this.bootstrapRequired, this.user});

  final bool bootstrapRequired;
  final UserModel? user;

  bool get isAuthenticated => user != null;

  factory AuthSnapshot.fromJson(Map<String, Object?> json) {
    final bootstrapRequired = json['bootstrapRequired'];
    if (bootstrapRequired is! bool) {
      throw const FormatException(
        'El campo "bootstrapRequired" debe ser booleano.',
      );
    }
    final user = json['user'];
    return AuthSnapshot(
      bootstrapRequired: bootstrapRequired,
      user: user == null
          ? null
          : UserModel.fromJson(user as Map<String, Object?>),
    );
  }

  Map<String, Object?> toJson() => {
    'bootstrapRequired': bootstrapRequired,
    'user': user?.toJson(),
  };
}
