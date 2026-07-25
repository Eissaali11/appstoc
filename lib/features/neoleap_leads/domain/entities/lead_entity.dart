/// Lead Lifecycle Statuses
enum LeadStatus {
  discovered,
  unassigned,
  assigned,
  contacted,
  visitPlanned,
  visited,
  interested,
  negotiation,
  won,
  lost,
  notEligible,
  duplicate,
}

extension LeadStatusX on LeadStatus {
  String get labelAr {
    switch (this) {
      case LeadStatus.discovered:
        return 'مُكتشف جديد';
      case LeadStatus.unassigned:
        return 'غير مُعيّن';
      case LeadStatus.assigned:
        return 'مُعيّن للفني';
      case LeadStatus.contacted:
        return 'تم التواصل';
      case LeadStatus.visitPlanned:
        return 'زيارة مبرمجة';
      case LeadStatus.visited:
        return 'تمت الزيارة';
      case LeadStatus.interested:
        return 'مهتم بالخدمة';
      case LeadStatus.negotiation:
        return 'قيد التفاوض';
      case LeadStatus.won:
        return 'عميل مكتسب (مكسب)';
      case LeadStatus.lost:
        return 'عميل مفقود';
      case LeadStatus.notEligible:
        return 'غير مؤهل';
      case LeadStatus.duplicate:
        return 'سجل مكرر';
    }
  }

  String get code {
    return toString().split('.').last.toUpperCase();
  }

  static LeadStatus fromCode(String? code) {
    switch ((code ?? '').toUpperCase()) {
      case 'DISCOVERED':
        return LeadStatus.discovered;
      case 'UNASSIGNED':
        return LeadStatus.unassigned;
      case 'ASSIGNED':
        return LeadStatus.assigned;
      case 'CONTACTED':
        return LeadStatus.contacted;
      case 'VISIT_PLANNED':
        return LeadStatus.visitPlanned;
      case 'VISITED':
        return LeadStatus.visited;
      case 'INTERESTED':
        return LeadStatus.interested;
      case 'NEGOTIATION':
        return LeadStatus.negotiation;
      case 'WON':
        return LeadStatus.won;
      case 'LOST':
        return LeadStatus.lost;
      case 'NOT_ELIGIBLE':
        return LeadStatus.notEligible;
      case 'DUPLICATE':
        return LeadStatus.duplicate;
      default:
        return LeadStatus.discovered;
    }
  }
}

/// Enterprise Potential Lead Entity for Saudi Geo Discovery Infrastructure
class LeadEntity {
  final String id;
  final String googlePlaceId;
  final String name;
  final String? businessName;
  final String category;
  final String? phone;
  final String? website;
  final double? rating;
  final int? ratingCount;
  final String? formattedAddress;
  final double latitude;
  final double longitude;
  final String? regionName;
  final String? cityName;
  final String? villageName;
  final String? district;
  final String? postalCode;
  final double distanceKm;
  final LeadStatus leadStatus;
  final bool isSent;
  final DateTime? sentAt;
  final DateTime discoveredAt;
  final DateTime? lastSeenAt;

  const LeadEntity({
    required this.id,
    required this.googlePlaceId,
    required this.name,
    this.businessName,
    this.category = 'نشاط تجاري',
    this.phone,
    this.website,
    this.rating,
    this.ratingCount,
    this.formattedAddress,
    required this.latitude,
    required this.longitude,
    this.regionName,
    this.cityName,
    this.villageName,
    this.district,
    this.postalCode,
    this.distanceKm = 0.0,
    this.leadStatus = LeadStatus.discovered,
    this.isSent = false,
    this.sentAt,
    required this.discoveredAt,
    this.lastSeenAt,
  });

  LeadEntity copyWith({
    String? id,
    String? googlePlaceId,
    String? name,
    String? businessName,
    String? category,
    String? phone,
    String? website,
    double? rating,
    int? ratingCount,
    String? formattedAddress,
    double? latitude,
    double? longitude,
    String? regionName,
    String? cityName,
    String? villageName,
    String? district,
    String? postalCode,
    double? distanceKm,
    LeadStatus? leadStatus,
    bool? isSent,
    DateTime? sentAt,
    DateTime? discoveredAt,
    DateTime? lastSeenAt,
  }) {
    return LeadEntity(
      id: id ?? this.id,
      googlePlaceId: googlePlaceId ?? this.googlePlaceId,
      name: name ?? this.name,
      businessName: businessName ?? this.businessName,
      category: category ?? this.category,
      phone: phone ?? this.phone,
      website: website ?? this.website,
      rating: rating ?? this.rating,
      ratingCount: ratingCount ?? this.ratingCount,
      formattedAddress: formattedAddress ?? this.formattedAddress,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      regionName: regionName ?? this.regionName,
      cityName: cityName ?? this.cityName,
      villageName: villageName ?? this.villageName,
      district: district ?? this.district,
      postalCode: postalCode ?? this.postalCode,
      distanceKm: distanceKm ?? this.distanceKm,
      leadStatus: leadStatus ?? this.leadStatus,
      isSent: isSent ?? this.isSent,
      sentAt: sentAt ?? this.sentAt,
      discoveredAt: discoveredAt ?? this.discoveredAt,
      lastSeenAt: lastSeenAt ?? this.lastSeenAt,
    );
  }
}
