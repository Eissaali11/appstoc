import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';

part 'received_device.g.dart';

@JsonSerializable()
class ReceivedDevice {
  final String? id;
  final String? technicianId;
  final String? supervisorId;

  @JsonKey(name: 'terminalId')
  final String terminalId;

  @JsonKey(name: 'serialNumber')
  final String serialNumber;

  final bool battery;

  @JsonKey(name: 'chargerCable')
  final bool chargerCable;

  @JsonKey(name: 'chargerHead')
  final bool chargerHead;

  @JsonKey(name: 'hasSim')
  final bool hasSim;

  @JsonKey(name: 'simCardType')
  final String? simCardType;

  @JsonKey(name: 'damagePart')
  final String? damagePart;

  final String? status; // pending | approved | rejected
  final String? adminNotes;
  final String? approvedBy;
  final DateTime? approvedAt;
  final DateTime? createdAt;

  ReceivedDevice({
    this.id,
    this.technicianId,
    this.supervisorId,
    required this.terminalId,
    required this.serialNumber,
    required this.battery,
    required this.chargerCable,
    required this.chargerHead,
    required this.hasSim,
    this.simCardType,
    this.damagePart,
    this.status,
    this.adminNotes,
    this.approvedBy,
    this.approvedAt,
    this.createdAt,
  });

  factory ReceivedDevice.fromJson(Map<String, dynamic> json) {
    return ReceivedDevice(
      id: json['id'] as String?,
      technicianId: json['technicianId'] as String?,
      supervisorId: json['supervisorId'] as String?,
      terminalId: json['terminalId'] as String? ?? '',
      serialNumber: json['serialNumber'] as String? ?? '',
      battery: json['battery'] as bool? ?? false,
      chargerCable: json['chargerCable'] as bool? ?? false,
      chargerHead: json['chargerHead'] as bool? ?? false,
      hasSim: json['hasSim'] as bool? ?? false,
      simCardType: json['simCardType'] as String?,
      damagePart: json['damagePart'] as String?,
      status: (json['status'] as String?)?.toLowerCase(),
      adminNotes: json['adminNotes'] as String?,
      approvedBy: json['approvedBy'] as String?,
      approvedAt: json['approvedAt'] != null
          ? DateTime.tryParse(json['approvedAt'] as String)
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String)
          : null,
    );
  }

  /// Only send fields needed for creating a received device.
  Map<String, dynamic> toJson() => <String, dynamic>{
        'terminalId': terminalId,
        'serialNumber': serialNumber,
        'battery': battery,
        'chargerCable': chargerCable,
        'chargerHead': chargerHead,
        'hasSim': hasSim,
        if (simCardType != null) 'simCardType': simCardType,
        if (damagePart != null) 'damagePart': damagePart,
      };

  int get accessoriesCount {
    int count = 0;
    if (battery) count++;
    if (chargerCable) count++;
    if (chargerHead) count++;
    if (hasSim) count++;
    return count;
  }

  String get statusText {
    final s = (status ?? '').toLowerCase();
    switch (s) {
      case 'approved':
      case 'accepted':
        return 'تمت الموافقة';
      case 'rejected':
        return 'مرفوض';
      case 'pending':
      default:
        return 'قيد الانتظار';
    }
  }

  int get _statusIndex {
    final s = (status ?? '').toLowerCase();
    switch (s) {
      case 'approved':
      case 'accepted':
        return 2;
      case 'rejected':
        return 3;
      case 'pending':
      default:
        return 1;
    }
  }

  // Map status index to color
  // 1: pending (orange), 2: approved (green), 3: rejected (red)
  // If status null -> grey
  get statusColor {
    switch (_statusIndex) {
      case 1:
        return const Color(0xFFF59E0B);
      case 2:
        return const Color(0xFF22C55E);
      case 3:
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFF9CA3AF);
    }
  }
}
