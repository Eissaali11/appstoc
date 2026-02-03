import 'package:json_annotation/json_annotation.dart';

part 'inventory_entry.g.dart';

@JsonSerializable()
class InventoryEntry {
  @JsonKey(name: 'itemTypeId')
  final String itemTypeId;
  final int boxes;
  final int units;

  InventoryEntry({
    required this.itemTypeId,
    required this.boxes,
    required this.units,
  });

  factory InventoryEntry.fromJson(Map<String, dynamic> json) =>
      _$InventoryEntryFromJson(json);

  Map<String, dynamic> toJson() => _$InventoryEntryToJson(this);
}
