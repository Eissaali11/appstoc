// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'inventory_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

InventoryRequest _$InventoryRequestFromJson(Map<String, dynamic> json) =>
    InventoryRequest(
      id: json['id'] as String,
      technicianId: json['technicianId'] as String,
      n950Boxes: (json['n950Boxes'] as num?)?.toInt(),
      n950Units: (json['n950Units'] as num?)?.toInt(),
      i9000sBoxes: (json['i9000sBoxes'] as num?)?.toInt(),
      i9000sUnits: (json['i9000sUnits'] as num?)?.toInt(),
      i9100Boxes: (json['i9100Boxes'] as num?)?.toInt(),
      i9100Units: (json['i9100Units'] as num?)?.toInt(),
      rollPaperBoxes: (json['rollPaperBoxes'] as num?)?.toInt(),
      rollPaperUnits: (json['rollPaperUnits'] as num?)?.toInt(),
      stickersBoxes: (json['stickersBoxes'] as num?)?.toInt(),
      stickersUnits: (json['stickersUnits'] as num?)?.toInt(),
      newBatteriesBoxes: (json['newBatteriesBoxes'] as num?)?.toInt(),
      newBatteriesUnits: (json['newBatteriesUnits'] as num?)?.toInt(),
      mobilySimBoxes: (json['mobilySimBoxes'] as num?)?.toInt(),
      mobilySimUnits: (json['mobilySimUnits'] as num?)?.toInt(),
      stcSimBoxes: (json['stcSimBoxes'] as num?)?.toInt(),
      stcSimUnits: (json['stcSimUnits'] as num?)?.toInt(),
      zainSimBoxes: (json['zainSimBoxes'] as num?)?.toInt(),
      zainSimUnits: (json['zainSimUnits'] as num?)?.toInt(),
      entries: (json['entries'] as List<dynamic>?)
          ?.map((e) => InventoryEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
      notes: json['notes'] as String?,
      status: json['status'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      respondedAt: json['respondedAt'] == null
          ? null
          : DateTime.parse(json['respondedAt'] as String),
      respondedBy: json['respondedBy'] as String?,
      adminNotes: json['adminNotes'] as String?,
      warehouseId: json['warehouseId'] as String?,
    );

Map<String, dynamic> _$InventoryRequestToJson(InventoryRequest instance) =>
    <String, dynamic>{
      'id': instance.id,
      'technicianId': instance.technicianId,
      'entries': instance.entries,
      'notes': instance.notes,
      'status': instance.status,
      'createdAt': instance.createdAt.toIso8601String(),
      'respondedAt': instance.respondedAt?.toIso8601String(),
      'respondedBy': instance.respondedBy,
      'adminNotes': instance.adminNotes,
      'warehouseId': instance.warehouseId,
    };
