// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'item_type.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ItemType _$ItemTypeFromJson(Map<String, dynamic> json) => ItemType(
      id: json['id'] as String,
      nameEn: json['nameEn'] as String,
      nameAr: json['nameAr'] as String,
      iconName: json['iconName'] as String?,
      colorHex: json['colorHex'] as String?,
      sortOrder: (json['sortOrder'] as num).toInt(),
      isActive: json['isActive'] as bool,
      isVisible: json['isVisible'] as bool,
    );

Map<String, dynamic> _$ItemTypeToJson(ItemType instance) => <String, dynamic>{
      'id': instance.id,
      'nameEn': instance.nameEn,
      'nameAr': instance.nameAr,
      'iconName': instance.iconName,
      'colorHex': instance.colorHex,
      'sortOrder': instance.sortOrder,
      'isActive': instance.isActive,
      'isVisible': instance.isVisible,
    };
