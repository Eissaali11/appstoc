class UserEntity {
  final String id;
  final String username;
  final String fullName;
  final String role;
  final String? regionId;
  final String? city;

  UserEntity({
    required this.id,
    required this.username,
    required this.fullName,
    required this.role,
    this.regionId,
    this.city,
  });
}
