// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'technician_inventory.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TechnicianInventory _$TechnicianInventoryFromJson(Map<String, dynamic> json) =>
    TechnicianInventory(
      id: json['id'] as String,
      technicianId: json['technicianId'] as String,
      n950Boxes: (json['n950Boxes'] as num?)?.toInt() ?? 0,
      n950Units: (json['n950Units'] as num?)?.toInt() ?? 0,
      i9000sBoxes: (json['i9000sBoxes'] as num?)?.toInt() ?? 0,
      i9000sUnits: (json['i9000sUnits'] as num?)?.toInt() ?? 0,
      i9100Boxes: (json['i9100Boxes'] as num?)?.toInt() ?? 0,
      i9100Units: (json['i9100Units'] as num?)?.toInt() ?? 0,
      rollPaperBoxes: (json['rollPaperBoxes'] as num?)?.toInt() ?? 0,
      rollPaperUnits: (json['rollPaperUnits'] as num?)?.toInt() ?? 0,
      stickersBoxes: (json['stickersBoxes'] as num?)?.toInt() ?? 0,
      stickersUnits: (json['stickersUnits'] as num?)?.toInt() ?? 0,
      newBatteriesBoxes: (json['newBatteriesBoxes'] as num?)?.toInt() ?? 0,
      newBatteriesUnits: (json['newBatteriesUnits'] as num?)?.toInt() ?? 0,
      mobilySimBoxes: (json['mobilySimBoxes'] as num?)?.toInt() ?? 0,
      mobilySimUnits: (json['mobilySimUnits'] as num?)?.toInt() ?? 0,
      stcSimBoxes: (json['stcSimBoxes'] as num?)?.toInt() ?? 0,
      stcSimUnits: (json['stcSimUnits'] as num?)?.toInt() ?? 0,
      zainSimBoxes: (json['zainSimBoxes'] as num?)?.toInt() ?? 0,
      zainSimUnits: (json['zainSimUnits'] as num?)?.toInt() ?? 0,
      entries: (json['entries'] as List<dynamic>?)
          ?.map((e) => InventoryEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$TechnicianInventoryToJson(
        TechnicianInventory instance) =>
    <String, dynamic>{
      'id': instance.id,
      'technicianId': instance.technicianId,
      'n950Boxes': instance.n950Boxes,
      'n950Units': instance.n950Units,
      'i9000sBoxes': instance.i9000sBoxes,
      'i9000sUnits': instance.i9000sUnits,
      'i9100Boxes': instance.i9100Boxes,
      'i9100Units': instance.i9100Units,
      'rollPaperBoxes': instance.rollPaperBoxes,
      'rollPaperUnits': instance.rollPaperUnits,
      'stickersBoxes': instance.stickersBoxes,
      'stickersUnits': instance.stickersUnits,
      'newBatteriesBoxes': instance.newBatteriesBoxes,
      'newBatteriesUnits': instance.newBatteriesUnits,
      'mobilySimBoxes': instance.mobilySimBoxes,
      'mobilySimUnits': instance.mobilySimUnits,
      'stcSimBoxes': instance.stcSimBoxes,
      'stcSimUnits': instance.stcSimUnits,
      'zainSimBoxes': instance.zainSimBoxes,
      'zainSimUnits': instance.zainSimUnits,
      'entries': instance.entries,
      'updatedAt': instance.updatedAt?.toIso8601String(),
    };
