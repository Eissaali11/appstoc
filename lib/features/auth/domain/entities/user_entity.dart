class UserEntity {
  final String id;
  final String username;
  final String fullName;
  final String role;
  final String? regionId;
  final String? city;
  final String? profileImage;

  UserEntity({
    required this.id,
    required this.username,
    required this.fullName,
    required this.role,
    this.regionId,
    this.city,
    this.profileImage,
  });

  UserEntity copyWith({
    String? id,
    String? username,
    String? fullName,
    String? role,
    String? regionId,
    String? city,
    String? profileImage,
  }) {
    return UserEntity(
      id: id ?? this.id,
      username: username ?? this.username,
      fullName: fullName ?? this.fullName,
      role: role ?? this.role,
      regionId: regionId ?? this.regionId,
      city: city ?? this.city,
      profileImage: profileImage ?? this.profileImage,
    );
  }
}
