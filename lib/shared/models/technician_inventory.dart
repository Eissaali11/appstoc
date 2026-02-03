import 'package:json_annotation/json_annotation.dart';
import '../../features/fixed_inventory/data/models/inventory_entry.dart';

part 'technician_inventory.g.dart';

@JsonSerializable()
class TechnicianInventory {
  final String id;
  final String technicianId;
  final int n950Boxes;
  final int n950Units;
  final int i9000sBoxes;
  final int i9000sUnits;
  final int i9100Boxes;
  final int i9100Units;
  final int rollPaperBoxes;
  final int rollPaperUnits;
  final int stickersBoxes;
  final int stickersUnits;
  final int newBatteriesBoxes;
  final int newBatteriesUnits;
  final int mobilySimBoxes;
  final int mobilySimUnits;
  final int stcSimBoxes;
  final int stcSimUnits;
  final int zainSimBoxes;
  final int zainSimUnits;
  final List<InventoryEntry>? entries;
  @JsonKey(name: 'updatedAt')
  final DateTime? updatedAt;

  TechnicianInventory({
    required this.id,
    required this.technicianId,
    this.n950Boxes = 0,
    this.n950Units = 0,
    this.i9000sBoxes = 0,
    this.i9000sUnits = 0,
    this.i9100Boxes = 0,
    this.i9100Units = 0,
    this.rollPaperBoxes = 0,
    this.rollPaperUnits = 0,
    this.stickersBoxes = 0,
    this.stickersUnits = 0,
    this.newBatteriesBoxes = 0,
    this.newBatteriesUnits = 0,
    this.mobilySimBoxes = 0,
    this.mobilySimUnits = 0,
    this.stcSimBoxes = 0,
    this.stcSimUnits = 0,
    this.zainSimBoxes = 0,
    this.zainSimUnits = 0,
    this.entries,
    this.updatedAt,
  });

  factory TechnicianInventory.fromJson(Map<String, dynamic> json) =>
      _$TechnicianInventoryFromJson(json);

  Map<String, dynamic> toJson() => _$TechnicianInventoryToJson(this);

  int get totalItems {
    return n950Boxes + n950Units +
        i9000sBoxes + i9000sUnits +
        i9100Boxes + i9100Units +
        rollPaperBoxes + rollPaperUnits +
        stickersBoxes + stickersUnits +
        newBatteriesBoxes + newBatteriesUnits +
        mobilySimBoxes + mobilySimUnits +
        stcSimBoxes + stcSimUnits +
        zainSimBoxes + zainSimUnits;
  }
}
