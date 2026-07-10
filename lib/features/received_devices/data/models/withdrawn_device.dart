class WithdrawnDevice {
  final String? id;
  final String city;
  final String technicianName;
  final String terminalId;
  final String serialNumber;
  final String battery;
  final String chargerCable;
  final String chargerHead;
  final String hasSim;
  final String? simCardType;
  final String? damagePart;
  final String? notes;
  final String? createdBy;
  final String? regionId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  WithdrawnDevice({
    this.id,
    required this.city,
    required this.technicianName,
    required this.terminalId,
    required this.serialNumber,
    required this.battery,
    required this.chargerCable,
    required this.chargerHead,
    required this.hasSim,
    this.simCardType,
    this.damagePart,
    this.notes,
    this.createdBy,
    this.regionId,
    this.createdAt,
    this.updatedAt,
  });

  factory WithdrawnDevice.fromJson(Map<String, dynamic> json) {
    return WithdrawnDevice(
      id: json['id'] as String?,
      city: json['city'] as String? ?? '',
      technicianName: json['technicianName'] as String? ?? '',
      terminalId: json['terminalId'] as String? ?? '',
      serialNumber: json['serialNumber'] as String? ?? '',
      battery: json['battery'] as String? ?? '',
      chargerCable: json['chargerCable'] as String? ?? '',
      chargerHead: json['chargerHead'] as String? ?? '',
      hasSim: json['hasSim'] as String? ?? '',
      simCardType: json['simCardType'] as String?,
      damagePart: json['damagePart'] as String?,
      notes: json['notes'] as String?,
      createdBy: json['createdBy'] as String?,
      regionId: json['regionId'] as String?,
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'] as String) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.tryParse(json['updatedAt'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'city': city,
    'technicianName': technicianName,
    'terminalId': terminalId,
    'serialNumber': serialNumber,
    'battery': battery,
    'chargerCable': chargerCable,
    'chargerHead': chargerHead,
    'hasSim': hasSim,
    if (simCardType != null && simCardType!.isNotEmpty) 'simCardType': simCardType,
    if (damagePart != null && damagePart!.isNotEmpty) 'damagePart': damagePart,
    if (notes != null && notes!.isNotEmpty) 'notes': notes,
  };
}
