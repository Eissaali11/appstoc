// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'warehouse_transfer.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

WarehouseTransfer _$WarehouseTransferFromJson(Map<String, dynamic> json) =>
    WarehouseTransfer(
      id: json['id'] as String,
      warehouseId: json['warehouseId'] as String,
      warehouseName: json['warehouseName'] as String?,
      technicianId: json['technicianId'] as String,
      technicianName: json['technicianName'] as String?,
      itemType: json['itemType'] as String,
      packagingType: json['packagingType'] as String,
      quantity: (json['quantity'] as num).toInt(),
      status: json['status'] as String,
      performedBy: json['performedBy'] as String?,
      performedByName: json['performedByName'] as String?,
      notes: json['notes'] as String?,
      rejectionReason: json['rejectionReason'] as String?,
      requestId: json['requestId'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$WarehouseTransferToJson(WarehouseTransfer instance) =>
    <String, dynamic>{
      'id': instance.id,
      'warehouseId': instance.warehouseId,
      'warehouseName': instance.warehouseName,
      'technicianId': instance.technicianId,
      'technicianName': instance.technicianName,
      'itemType': instance.itemType,
      'packagingType': instance.packagingType,
      'quantity': instance.quantity,
      'status': instance.status,
      'performedBy': instance.performedBy,
      'performedByName': instance.performedByName,
      'notes': instance.notes,
      'rejectionReason': instance.rejectionReason,
      'requestId': instance.requestId,
      'createdAt': instance.createdAt.toIso8601String(),
    };
