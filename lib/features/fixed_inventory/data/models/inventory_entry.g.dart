// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'inventory_entry.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

InventoryEntry _$InventoryEntryFromJson(Map<String, dynamic> json) =>
    InventoryEntry(
      itemTypeId: json['itemTypeId'] as String,
      boxes: (json['boxes'] as num).toInt(),
      units: (json['units'] as num).toInt(),
    );

Map<String, dynamic> _$InventoryEntryToJson(InventoryEntry instance) =>
    <String, dynamic>{
      'itemTypeId': instance.itemTypeId,
      'boxes': instance.boxes,
      'units': instance.units,
    };
