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
  final String? category;
  @JsonKey(name: 'requiresSerial')
  final bool? requiresSerial;
  @JsonKey(name: 'serialPrefix')
  final String? serialPrefix;
  @JsonKey(name: 'serialLength')
  final int? serialLength;
  @JsonKey(name: 'serialRegex')
  final String? serialRegex;

  ItemType({
    required this.id,
    required this.nameEn,
    required String nameAr,
    this.iconName,
    this.colorHex,
    required this.sortOrder,
    required this.isActive,
    required this.isVisible,
    this.category,
    this.requiresSerial,
    this.serialPrefix,
    this.serialLength,
    this.serialRegex,
  }) : nameAr = _sanitizeNameAr(id, nameAr);

  static String _sanitizeNameAr(String id, String nameAr) {
    if (id.toLowerCase() == 'n950' ||
        nameAr.toLowerCase().contains('n950') ||
        nameAr.contains('ان 950') ||
        nameAr.contains('ان950') ||
        nameAr.contains('ن 950') ||
        nameAr.contains('ن950') ||
        nameAr.contains('ن ٩٥٠') ||
        nameAr.contains('ان ٩٥٠')) {
      return 'N950';
    }
    return nameAr;
  }

  factory ItemType.fromJson(Map<String, dynamic> json) =>
      _$ItemTypeFromJson(json);

  Map<String, dynamic> toJson() => _$ItemTypeToJson(this);
}
