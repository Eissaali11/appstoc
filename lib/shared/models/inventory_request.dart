import 'package:json_annotation/json_annotation.dart';
import '../../features/fixed_inventory/data/models/inventory_entry.dart';

part 'inventory_request.g.dart';

@JsonSerializable()
class InventoryRequest {
  final String id;
  final String technicianId;
  
  // Legacy fields (for backward compatibility with API)
  @JsonKey(includeFromJson: true, includeToJson: false)
  final int? n950Boxes;
  @JsonKey(includeFromJson: true, includeToJson: false)
  final int? n950Units;
  @JsonKey(includeFromJson: true, includeToJson: false)
  final int? i9000sBoxes;
  @JsonKey(includeFromJson: true, includeToJson: false)
  final int? i9000sUnits;
  @JsonKey(includeFromJson: true, includeToJson: false)
  final int? i9100Boxes;
  @JsonKey(includeFromJson: true, includeToJson: false)
  final int? i9100Units;
  @JsonKey(includeFromJson: true, includeToJson: false)
  final int? rollPaperBoxes;
  @JsonKey(includeFromJson: true, includeToJson: false)
  final int? rollPaperUnits;
  @JsonKey(includeFromJson: true, includeToJson: false)
  final int? stickersBoxes;
  @JsonKey(includeFromJson: true, includeToJson: false)
  final int? stickersUnits;
  @JsonKey(includeFromJson: true, includeToJson: false)
  final int? newBatteriesBoxes;
  @JsonKey(includeFromJson: true, includeToJson: false)
  final int? newBatteriesUnits;
  @JsonKey(includeFromJson: true, includeToJson: false)
  final int? mobilySimBoxes;
  @JsonKey(includeFromJson: true, includeToJson: false)
  final int? mobilySimUnits;
  @JsonKey(includeFromJson: true, includeToJson: false)
  final int? stcSimBoxes;
  @JsonKey(includeFromJson: true, includeToJson: false)
  final int? stcSimUnits;
  @JsonKey(includeFromJson: true, includeToJson: false)
  final int? zainSimBoxes;
  @JsonKey(includeFromJson: true, includeToJson: false)
  final int? zainSimUnits;
  
  // Dynamic entries (preferred method)
  @JsonKey(name: 'entries')
  final List<InventoryEntry>? entries;
  
  final String? notes;
  final String status; // 'pending', 'approved', 'rejected'
  final DateTime createdAt;
  @JsonKey(name: 'respondedAt')
  final DateTime? respondedAt;
  final String? respondedBy;
  final String? adminNotes;
  final String? warehouseId;

  InventoryRequest({
    required this.id,
    required this.technicianId,
    this.n950Boxes,
    this.n950Units,
    this.i9000sBoxes,
    this.i9000sUnits,
    this.i9100Boxes,
    this.i9100Units,
    this.rollPaperBoxes,
    this.rollPaperUnits,
    this.stickersBoxes,
    this.stickersUnits,
    this.newBatteriesBoxes,
    this.newBatteriesUnits,
    this.mobilySimBoxes,
    this.mobilySimUnits,
    this.stcSimBoxes,
    this.stcSimUnits,
    this.zainSimBoxes,
    this.zainSimUnits,
    this.entries,
    this.notes,
    required this.status,
    required this.createdAt,
    this.respondedAt,
    this.respondedBy,
    this.adminNotes,
    this.warehouseId,
  });

  factory InventoryRequest.fromJson(Map<String, dynamic> json) =>
      _$InventoryRequestFromJson(json);

  Map<String, dynamic> toJson() {
    // Always use entries for sending to API (dynamic approach)
    return {
      'id': id,
      'technicianId': technicianId,
      if (entries != null && entries!.isNotEmpty) 'entries': entries!.map((e) => e.toJson()).toList(),
      if (notes != null) 'notes': notes,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      if (respondedAt != null) 'respondedAt': respondedAt!.toIso8601String(),
      if (respondedBy != null) 'respondedBy': respondedBy,
      if (adminNotes != null) 'adminNotes': adminNotes,
      if (warehouseId != null) 'warehouseId': warehouseId,
    };
  }

  int get totalItems {
    if (entries != null && entries!.isNotEmpty) {
      return entries!.fold(0, (sum, entry) => sum + entry.boxes + entry.units);
    }
    // Fallback to legacy fields
    return (n950Boxes ?? 0) + (n950Units ?? 0) +
        (i9000sBoxes ?? 0) + (i9000sUnits ?? 0) +
        (i9100Boxes ?? 0) + (i9100Units ?? 0) +
        (rollPaperBoxes ?? 0) + (rollPaperUnits ?? 0) +
        (stickersBoxes ?? 0) + (stickersUnits ?? 0) +
        (newBatteriesBoxes ?? 0) + (newBatteriesUnits ?? 0) +
        (mobilySimBoxes ?? 0) + (mobilySimUnits ?? 0) +
        (stcSimBoxes ?? 0) + (stcSimUnits ?? 0) +
        (zainSimBoxes ?? 0) + (zainSimUnits ?? 0);
  }
}
