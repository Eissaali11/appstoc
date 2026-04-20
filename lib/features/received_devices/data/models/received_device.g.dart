// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'received_device.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ReceivedDevice _$ReceivedDeviceFromJson(Map<String, dynamic> json) =>
    ReceivedDevice(
      id: json['id'] as String?,
      technicianId: json['technicianId'] as String?,
      supervisorId: json['supervisorId'] as String?,
      terminalId: json['terminalId'] as String,
      serialNumber: json['serialNumber'] as String,
      battery: json['battery'] as bool,
      chargerCable: json['chargerCable'] as bool,
      chargerHead: json['chargerHead'] as bool,
      hasSim: json['hasSim'] as bool,
      simCardType: json['simCardType'] as String?,
      damagePart: json['damagePart'] as String?,
      status: json['status'] as String?,
      adminNotes: json['adminNotes'] as String?,
      approvedBy: json['approvedBy'] as String?,
      approvedAt: json['approvedAt'] == null
          ? null
          : DateTime.parse(json['approvedAt'] as String),
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$ReceivedDeviceToJson(ReceivedDevice instance) =>
    <String, dynamic>{
      'id': instance.id,
      'technicianId': instance.technicianId,
      'supervisorId': instance.supervisorId,
      'terminalId': instance.terminalId,
      'serialNumber': instance.serialNumber,
      'battery': instance.battery,
      'chargerCable': instance.chargerCable,
      'chargerHead': instance.chargerHead,
      'hasSim': instance.hasSim,
      'simCardType': instance.simCardType,
      'damagePart': instance.damagePart,
      'status': instance.status,
      'adminNotes': instance.adminNotes,
      'approvedBy': instance.approvedBy,
      'approvedAt': instance.approvedAt?.toIso8601String(),
      'createdAt': instance.createdAt?.toIso8601String(),
    };
