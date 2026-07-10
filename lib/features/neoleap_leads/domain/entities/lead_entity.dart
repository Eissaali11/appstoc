class LeadEntity {
  final String id;
  final String name;
  final String? phone;
  final String? address;
  final double? rating;
  final bool isSent;
  final DateTime? sentAt;
  final double latitude;
  final double longitude;

  const LeadEntity({
    required this.id,
    required this.name,
    this.phone,
    this.address,
    this.rating,
    this.isSent = false,
    this.sentAt,
    required this.latitude,
    required this.longitude,
  });

  LeadEntity copyWith({
    String? id,
    String? name,
    String? phone,
    String? address,
    double? rating,
    bool? isSent,
    DateTime? sentAt,
    double? latitude,
    double? longitude,
  }) {
    return LeadEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      rating: rating ?? this.rating,
      isSent: isSent ?? this.isSent,
      sentAt: sentAt ?? this.sentAt,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
    );
  }
}
