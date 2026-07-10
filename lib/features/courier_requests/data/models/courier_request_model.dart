import 'package:flutter/material.dart';

class CourierRequest {
  final int id;
  final String? date;
  final String? installationType;
  final String? sim;
  final String? tid;
  final String? otp;
  final String? ticketingHolouly;
  final String? incidentNumber;
  final String? pinCode;
  final String? trsm;
  final String? terminalId;
  final String? simSn;
  final String? idData;
  final String? vendorType;
  final String? city;
  final String? cityTec;
  final String? customerName;
  final String? retailerName;
  final String? addressAr;
  final String? addressEn;
  final String? mobile;
  final String? mobile2;
  final String? tecName;
  final String? createdByName;
  final String? installationStatus;
  final String? sn;
  final String? simSerial;
  final String? simType;
  final String? customerNotes;
  final int version;

  CourierRequest({
    required this.id,
    this.date,
    this.installationType,
    this.sim,
    this.tid,
    this.otp,
    this.ticketingHolouly,
    this.incidentNumber,
    this.pinCode,
    this.trsm,
    this.terminalId,
    this.simSn,
    this.idData,
    this.vendorType,
    this.city,
    this.cityTec,
    this.customerName,
    this.retailerName,
    this.addressAr,
    this.addressEn,
    this.mobile,
    this.mobile2,
    this.tecName,
    this.createdByName,
    this.installationStatus,
    this.sn,
    this.simSerial,
    this.simType,
    this.customerNotes,
    required this.version,
  });

  factory CourierRequest.fromJson(Map<String, dynamic> json) {
    final exec = json['execution'] as Map<String, dynamic>?;
    return CourierRequest(
      id: json['id'] as int,
      date: json['date'] as String?,
      installationType: json['installationType'] as String?,
      sim: json['sim'] as String?,
      tid: json['tid'] as String?,
      otp: json['otp'] as String?,
      ticketingHolouly: json['ticketingHolouly'] as String?,
      incidentNumber: json['incidentNumber'] as String?,
      pinCode: json['pinCode'] as String?,
      trsm: json['trsm'] as String?,
      terminalId: json['terminalId'] as String?,
      simSn: json['simSn'] as String?,
      idData: json['idData'] as String?,
      vendorType: json['vendorType'] as String?,
      city: json['city'] as String?,
      cityTec: json['cityTec'] as String?,
      customerName: json['customerName'] as String?,
      retailerName: json['retailerName'] as String?,
      addressAr: json['addressAr'] as String?,
      addressEn: json['addressEn'] as String?,
      mobile: json['mobile'] as String?,
      mobile2: json['mobile2'] as String?,
      tecName: json['tecName'] as String?,
      createdByName: json['created_by_name'] as String?,
      installationStatus: exec?['installationStatus'] as String?,
      sn: exec?['sn'] as String?,
      simSerial: exec?['simSerial'] as String?,
      simType: exec?['simType'] as String?,
      customerNotes: exec?['customerNotes'] as String?,
      version: json['version'] as int? ?? 1,
    );
  }

  String get statusText {
    final s = (installationStatus ?? '').toUpperCase();
    switch (s) {
      case 'ASSIGNED':
        return 'بانتظار قبولك';
      case 'ACCEPTED':
        return 'تم القبول';
      case 'RECEIVING':
        return 'جاري الاستلام والتحقق';
      case 'RECEIVED':
        return 'مستلم بالكامل';
      case 'PARTIALLY_RECEIVED':
        return 'مستلم جزئياً';
      case 'ON_ROUTE':
        return 'في الطريق للعميل';
      case 'ARRIVED':
        return 'تم الوصول للعميل';
      case 'INSTALLING':
        return 'جاري التركيب والتشغيل';
      case 'REJECTED':
        return 'مرفوض';
      case 'COMPLETED':
      case 'INSTALLATION COMPLETED':
      case 'INSTALLATION COMPLETED - NL':
        return 'تم التركيب';
      default:
        return 'طلب جديد';
    }
  }

  Color get statusColor {
    final s = (installationStatus ?? '').toUpperCase();
    switch (s) {
      case 'ASSIGNED':
        return const Color(0xFFF59E0B); // Amber
      case 'ACCEPTED':
        return const Color(0xFF3B82F6); // Blue
      case 'RECEIVING':
        return const Color(0xFF8B5CF6); // Purple
      case 'RECEIVED':
        return const Color(0xFF10B981); // Emerald
      case 'PARTIALLY_RECEIVED':
        return const Color(0xFF06B6D4); // Cyan
      case 'ON_ROUTE':
        return const Color(0xFF14B8A6); // Teal
      case 'ARRIVED':
        return const Color(0xFFF97316); // Orange
      case 'INSTALLING':
        return const Color(0xFF3B82F6); // Blue
      case 'REJECTED':
        return const Color(0xFFEF4444); // Red
      case 'COMPLETED':
      case 'INSTALLATION COMPLETED':
      case 'INSTALLATION COMPLETED - NL':
        return const Color(0xFF10B981);
      default:
        return const Color(0xFF9CA3AF); // Grey
    }
  }
}

class CourierRequestItem {
  final int id;
  final int requestId;
  final String itemType;
  final int? inventoryItemId;
  final String? serialNumber;
  final String? simSerial;
  final int quantity;
  final String status;
  final DateTime? scannedAt;
  final DateTime? receivedAt;
  final DateTime? installedAt;
  final DateTime? deliveredAt;
  final String? technicianId;

  CourierRequestItem({
    required this.id,
    required this.requestId,
    required this.itemType,
    this.inventoryItemId,
    this.serialNumber,
    this.simSerial,
    required this.quantity,
    required this.status,
    this.scannedAt,
    this.receivedAt,
    this.installedAt,
    this.deliveredAt,
    this.technicianId,
  });

  factory CourierRequestItem.fromJson(Map<String, dynamic> json) {
    return CourierRequestItem(
      id: json['id'] as int,
      requestId: json['requestId'] as int,
      itemType: json['itemType'] as String,
      inventoryItemId: json['inventoryItemId'] as int?,
      serialNumber: json['serialNumber'] as String?,
      simSerial: json['simSerial'] as String?,
      quantity: json['quantity'] as int? ?? 1,
      status: json['status'] as String? ?? 'PENDING_RECEIPT',
      scannedAt: json['scannedAt'] != null ? DateTime.tryParse(json['scannedAt'] as String) : null,
      receivedAt: json['receivedAt'] != null ? DateTime.tryParse(json['receivedAt'] as String) : null,
      installedAt: json['installedAt'] != null ? DateTime.tryParse(json['installedAt'] as String) : null,
      deliveredAt: json['deliveredAt'] != null ? DateTime.tryParse(json['deliveredAt'] as String) : null,
      technicianId: json['technicianId'] as String?,
    );
  }

  String get statusText {
    final s = status.toUpperCase();
    switch (s) {
      case 'PENDING_RECEIPT':
        return 'بانتظار التحقق';
      case 'RECEIVED':
        return 'تم التحقق والاستلام';
      case 'INSTALLED':
        return 'تم التركيب';
      case 'DELIVERED':
        return 'تم التسليم للعميل';
      case 'REJECTED':
        return 'مرفوض';
      case 'MISSING':
        return 'مفقود';
      default:
        return status;
    }
  }

  Color get statusColor {
    final s = status.toUpperCase();
    switch (s) {
      case 'PENDING_RECEIPT':
        return const Color(0xFFF59E0B);
      case 'RECEIVED':
        return const Color(0xFF10B981);
      case 'INSTALLED':
        return const Color(0xFF3B82F6);
      case 'DELIVERED':
        return const Color(0xFF10B981);
      case 'REJECTED':
        return const Color(0xFFEF4444);
      case 'MISSING':
        return const Color(0xFF6B7280);
      default:
        return const Color(0xFF9CA3AF);
    }
  }
}
