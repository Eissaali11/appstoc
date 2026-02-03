import 'package:json_annotation/json_annotation.dart';

part 'warehouse_transfer.g.dart';

@JsonSerializable()
class WarehouseTransfer {
  final String id;
  @JsonKey(name: 'warehouseId')
  final String warehouseId;
  @JsonKey(name: 'warehouseName')
  final String? warehouseName;
  @JsonKey(name: 'technicianId')
  final String technicianId;
  @JsonKey(name: 'technicianName')
  final String? technicianName;
  @JsonKey(name: 'itemType')
  final String itemType;
  @JsonKey(name: 'packagingType')
  final String packagingType; // "boxes" | "units"
  final int quantity;
  final String status; // "pending" | "accepted" | "rejected"
  @JsonKey(name: 'performedBy')
  final String? performedBy;
  @JsonKey(name: 'performedByName')
  final String? performedByName;
  final String? notes;
  @JsonKey(name: 'rejectionReason')
  final String? rejectionReason;
  @JsonKey(name: 'requestId')
  final String? requestId;
  @JsonKey(name: 'createdAt')
  final DateTime createdAt;

  WarehouseTransfer({
    required this.id,
    required this.warehouseId,
    this.warehouseName,
    required this.technicianId,
    this.technicianName,
    required this.itemType,
    required this.packagingType,
    required this.quantity,
    required this.status,
    this.performedBy,
    this.performedByName,
    this.notes,
    this.rejectionReason,
    this.requestId,
    required this.createdAt,
  });

  factory WarehouseTransfer.fromJson(Map<String, dynamic> json) =>
      _$WarehouseTransferFromJson(json);

  Map<String, dynamic> toJson() => _$WarehouseTransferToJson(this);
}
