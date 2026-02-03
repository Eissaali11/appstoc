import 'package:json_annotation/json_annotation.dart';

part 'item_type.g.dart';

@JsonSerializable()
class ItemType {
  final String id;
  @JsonKey(name: 'nameEn')
  final String nameEn;
  @JsonKey(name: 'nameAr')
  final String nameAr;
  @JsonKey(name: 'iconName')
  final String? iconName;
  @JsonKey(name: 'colorHex')
  final String? colorHex;
  @JsonKey(name: 'sortOrder')
  final int sortOrder;
  @JsonKey(name: 'isActive')
  final bool isActive;
  @JsonKey(name: 'isVisible')
  final bool isVisible;

  ItemType({
    required this.id,
    required this.nameEn,
    required this.nameAr,
    this.iconName,
    this.colorHex,
    required this.sortOrder,
    required this.isActive,
    required this.isVisible,
  });

  factory ItemType.fromJson(Map<String, dynamic> json) =>
      _$ItemTypeFromJson(json);

  Map<String, dynamic> toJson() => _$ItemTypeToJson(this);
}
