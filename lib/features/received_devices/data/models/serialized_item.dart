class SerializedItem {
  final String? id;
  final String? itemTypeId;
  final String serialNumber;
  final String barcode;
  final String status;
  final String? currentOwnerId;
  final String? warehouseId;
  final String? carrierName;
  final String? simPackageType;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  
  // Joins from API
  final String? itemTypeNameAr;
  final String? itemTypeNameEn;
  final String? ownerName;
  final String? ownerUsername;
  final List<SerializedItemHistoryLog>? history;

  SerializedItem({
    this.id,
    this.itemTypeId,
    required this.serialNumber,
    required this.barcode,
    required this.status,
    this.currentOwnerId,
    this.warehouseId,
    this.carrierName,
    this.simPackageType,
    this.createdAt,
    this.updatedAt,
    this.itemTypeNameAr,
    this.itemTypeNameEn,
    this.ownerName,
    this.ownerUsername,
    this.history,
  });

  factory SerializedItem.fromJson(Map<String, dynamic> json) {
    return SerializedItem(
      id: json['id'] as String?,
      itemTypeId: json['itemTypeId'] as String?,
      serialNumber: json['serialNumber'] as String? ?? '',
      barcode: json['barcode'] as String? ?? '',
      status: json['status'] as String? ?? 'WAREHOUSE',
      currentOwnerId: json['currentOwnerId'] as String?,
      warehouseId: json['warehouseId'] as String?,
      carrierName: json['carrierName'] as String?,
      simPackageType: json['simPackageType'] as String?,
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'] as String) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.tryParse(json['updatedAt'] as String) : null,
      itemTypeNameAr: json['itemTypeNameAr'] as String?,
      itemTypeNameEn: json['itemTypeNameEn'] as String?,
      ownerName: json['ownerName'] as String?,
      ownerUsername: json['ownerUsername'] as String?,
      history: json['history'] != null
          ? (json['history'] as List)
              .map((e) => SerializedItemHistoryLog.fromJson(e as Map<String, dynamic>))
              .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'itemTypeId': itemTypeId,
      'serialNumber': serialNumber,
      'barcode': barcode,
      'status': status,
      'currentOwnerId': currentOwnerId,
      'warehouseId': warehouseId,
      'carrierName': carrierName,
      'simPackageType': simPackageType,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'itemTypeNameAr': itemTypeNameAr,
      'itemTypeNameEn': itemTypeNameEn,
      'ownerName': ownerName,
      'ownerUsername': ownerUsername,
      'history': history?.map((e) => e.toJson()).toList(),
    };
  }
}

class SerializedItemHistoryLog {
  final String? id;
  final String? itemId;
  final String fromStatus;
  final String toStatus;
  final String? changedByName;
  final DateTime? changedAt;
  final String? notes;

  SerializedItemHistoryLog({
    this.id,
    this.itemId,
    required this.fromStatus,
    required this.toStatus,
    this.changedByName,
    this.changedAt,
    this.notes,
  });

  factory SerializedItemHistoryLog.fromJson(Map<String, dynamic> json) {
    return SerializedItemHistoryLog(
      id: json['id'] as String?,
      itemId: json['itemId'] as String?,
      fromStatus: json['fromStatus'] as String? ?? '',
      toStatus: json['toStatus'] as String? ?? '',
      changedByName: json['changedByName'] as String?,
      changedAt: json['changedAt'] != null ? DateTime.tryParse(json['changedAt'] as String) : null,
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'itemId': itemId,
      'fromStatus': fromStatus,
      'toStatus': toStatus,
      'changedByName': changedByName,
      'changedAt': changedAt?.toIso8601String(),
      'notes': notes,
    };
  }
}
