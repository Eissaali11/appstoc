import '../../domain/entities/lead_entity.dart';

class LeadModel extends LeadEntity {
  const LeadModel({
    required super.id,
    required super.name,
    super.phone,
    super.address,
    super.rating,
    super.isSent,
    super.sentAt,
    required super.latitude,
    required super.longitude,
  });

  factory LeadModel.fromJson(Map<String, dynamic> json) {
    return LeadModel(
      id: json['id'] as String,
      name: json['name'] as String,
      phone: json['phone'] as String?,
      address: json['address'] as String?,
      rating: (json['rating'] as num?)?.toDouble(),
      isSent: json['isSent'] as bool? ?? false,
      sentAt: json['sentAt'] != null ? DateTime.parse(json['sentAt'] as String) : null,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'address': address,
      'rating': rating,
      'isSent': isSent,
      'sentAt': sentAt?.toIso8601String(),
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  factory LeadModel.fromEntity(LeadEntity entity) {
    return LeadModel(
      id: entity.id,
      name: entity.name,
      phone: entity.phone,
      address: entity.address,
      rating: entity.rating,
      isSent: entity.isSent,
      sentAt: entity.sentAt,
      latitude: entity.latitude,
      longitude: entity.longitude,
    );
  }
}
