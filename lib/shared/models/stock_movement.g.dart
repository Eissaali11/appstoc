// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'stock_movement.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

StockMovement _$StockMovementFromJson(Map<String, dynamic> json) =>
    StockMovement(
      id: json['id'] as String,
      technicianId: json['technicianId'] as String,
      itemType: json['itemType'] as String,
      packagingType: json['packagingType'] as String,
      quantity: (json['quantity'] as num).toInt(),
      fromInventory: json['fromInventory'] as String,
      toInventory: json['toInventory'] as String,
      reason: json['reason'] as String?,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$StockMovementToJson(StockMovement instance) =>
    <String, dynamic>{
      'id': instance.id,
      'technicianId': instance.technicianId,
      'itemType': instance.itemType,
      'packagingType': instance.packagingType,
      'quantity': instance.quantity,
      'fromInventory': instance.fromInventory,
      'toInventory': instance.toInventory,
      'reason': instance.reason,
      'notes': instance.notes,
      'createdAt': instance.createdAt.toIso8601String(),
    };
