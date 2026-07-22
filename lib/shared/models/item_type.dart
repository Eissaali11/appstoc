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

  factory ItemType.fromJson(Map<String, dynamic> json) {
    // Accept both camelCase (API) and snake_case (raw/cache) field names.
    final normalized = <String, dynamic>{
      ...json,
      'nameEn': json['nameEn'] ?? json['name_en'] ?? '',
      'nameAr': json['nameAr'] ?? json['name_ar'] ?? '',
      'iconName': json['iconName'] ?? json['icon_name'] ?? json['icon'],
      'colorHex': json['colorHex'] ?? json['color_hex'] ?? json['color'],
      'sortOrder': json['sortOrder'] ?? json['sort_order'] ?? 0,
      'isActive': json['isActive'] ?? json['is_active'] ?? true,
      'isVisible': json['isVisible'] ?? json['is_visible'] ?? true,
      'requiresSerial': json['requiresSerial'] ?? json['requires_serial'],
      'serialPrefix': json['serialPrefix'] ?? json['serial_prefix'],
      'serialLength': json['serialLength'] ?? json['serial_length'],
      'serialRegex': json['serialRegex'] ?? json['serial_regex'],
      'category': (json['category'] as String?)?.trim().toLowerCase(),
    };
    return _$ItemTypeFromJson(normalized);
  }

  Map<String, dynamic> toJson() => _$ItemTypeToJson(this);
}
