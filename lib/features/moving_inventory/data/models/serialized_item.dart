class SerializedItem {
  final String id;
  final String serialNumber;
  final String status;
  final String? carrierName;
  final String? itemTypeNameAr;
  final String? itemTypeNameEn;
  final DateTime createdAt;

  SerializedItem({
    required this.id,
    required this.serialNumber,
    required this.status,
    this.carrierName,
    this.itemTypeNameAr,
    this.itemTypeNameEn,
    required this.createdAt,
  });

  factory SerializedItem.fromJson(Map<String, dynamic> json) {
    return SerializedItem(
      id: json['id'] as String,
      serialNumber: json['serialNumber'] as String,
      status: json['status'] as String? ?? 'RECEIVED_BY_TECHNICIAN',
      carrierName: json['carrierName'] as String?,
      itemTypeNameAr: json['itemTypeNameAr'] as String?,
      itemTypeNameEn: json['itemTypeNameEn'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
    );
  }

  bool get isSim => carrierName != null && carrierName!.isNotEmpty;

  String get displayName => itemTypeNameAr ?? itemTypeNameEn ?? serialNumber;

  String get shortSerial {
    if (serialNumber.length <= 12) return serialNumber;
    return '${serialNumber.substring(0, 6)}...${serialNumber.substring(serialNumber.length - 4)}';
  }
}
