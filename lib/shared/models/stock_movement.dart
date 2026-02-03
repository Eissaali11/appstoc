import 'package:json_annotation/json_annotation.dart';

part 'stock_movement.g.dart';

@JsonSerializable()
class StockMovement {
  final String id;
  final String technicianId;
  final String itemType;
  final String packagingType; // 'box' or 'unit'
  final int quantity;
  final String fromInventory; // 'fixed' or 'moving'
  final String toInventory; // 'fixed' or 'moving'
  final String? reason;
  final String? notes;
  @JsonKey(name: 'createdAt')
  final DateTime createdAt;

  StockMovement({
    required this.id,
    required this.technicianId,
    required this.itemType,
    required this.packagingType,
    required this.quantity,
    required this.fromInventory,
    required this.toInventory,
    this.reason,
    this.notes,
    required this.createdAt,
  });

  factory StockMovement.fromJson(Map<String, dynamic> json) =>
      _$StockMovementFromJson(json);

  Map<String, dynamic> toJson() => _$StockMovementToJson(this);
}
