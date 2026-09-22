class UserModel {
  final String id;
  final String email;
  final String fullName;
  final List<UserRoleModel> roles;

  UserModel({
    required this.id,
    required this.email,
    required this.fullName,
    required this.roles,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      fullName: json['fullName'] ?? json['email'] ?? '',
      roles: (json['roles'] as List<dynamic>?)
              ?.map((r) => UserRoleModel.fromJson(r as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  bool hasRole(String roleCode) =>
      roles.any((r) => r.role == roleCode || r.role == 'super_admin');
}

class UserRoleModel {
  final String role;
  final String? roleName;
  final String? orgUnitId;
  final String? orgUnitName;

  UserRoleModel({
    required this.role,
    this.roleName,
    this.orgUnitId,
    this.orgUnitName,
  });

  factory UserRoleModel.fromJson(Map<String, dynamic> json) {
    return UserRoleModel(
      role: json['role'] ?? json['roleCode'] ?? '',
      roleName: json['roleName'],
      orgUnitId: json['orgUnitId'],
      orgUnitName: json['orgUnitName'],
    );
  }
}
