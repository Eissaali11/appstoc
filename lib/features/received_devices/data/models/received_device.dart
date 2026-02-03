import 'package:json_annotation/json_annotation.dart';

part 'received_device.g.dart';

@JsonSerializable()
class ReceivedDevice {
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
  final String damagePart;

  ReceivedDevice({
    required this.terminalId,
    required this.serialNumber,
    required this.battery,
    required this.chargerCable,
    required this.chargerHead,
    required this.hasSim,
    this.simCardType,
    required this.damagePart,
  });

  factory ReceivedDevice.fromJson(Map<String, dynamic> json) =>
      _$ReceivedDeviceFromJson(json);

  Map<String, dynamic> toJson() => _$ReceivedDeviceToJson(this);
}
