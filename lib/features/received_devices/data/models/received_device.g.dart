// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'received_device.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ReceivedDevice _$ReceivedDeviceFromJson(Map<String, dynamic> json) =>
    ReceivedDevice(
      terminalId: json['terminalId'] as String,
      serialNumber: json['serialNumber'] as String,
      battery: json['battery'] as bool,
      chargerCable: json['chargerCable'] as bool,
      chargerHead: json['chargerHead'] as bool,
      hasSim: json['hasSim'] as bool,
      simCardType: json['simCardType'] as String?,
      damagePart: json['damagePart'] as String,
    );

Map<String, dynamic> _$ReceivedDeviceToJson(ReceivedDevice instance) =>
    <String, dynamic>{
      'terminalId': instance.terminalId,
      'serialNumber': instance.serialNumber,
      'battery': instance.battery,
      'chargerCable': instance.chargerCable,
      'chargerHead': instance.chargerHead,
      'hasSim': instance.hasSim,
      'simCardType': instance.simCardType,
      'damagePart': instance.damagePart,
    };
