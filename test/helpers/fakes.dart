// PHASE B1.4 — Flutter Test Foundation: fake domain-object factories.
// Plain-object factories with sane defaults, overridable per test — mirrors
// the backend's fixtures.ts convention from Phase B1.1 for consistency
// across the whole platform's test infrastructure.
import 'package:dio/dio.dart';
import 'package:nuolipapp/features/auth/domain/entities/user_entity.dart';
import 'package:nuolipapp/features/received_devices/data/models/received_device.dart';
import 'package:nuolipapp/features/courier_requests/data/models/courier_request_model.dart';

UserEntity createFakeUser({
  String id = 'fake-user-id',
  String username = 'fake.technician',
  String fullName = 'Fake Technician',
  String role = 'technician',
  String? regionId,
  String? city,
}) {
  return UserEntity(
    id: id,
    username: username,
    fullName: fullName,
    role: role,
    regionId: regionId,
    city: city,
  );
}

UserEntity createFakeTechnician({String id = 'fake-technician-id'}) =>
    createFakeUser(id: id, role: 'technician');

UserEntity createFakeSupervisor({String id = 'fake-supervisor-id'}) =>
    createFakeUser(id: id, role: 'supervisor', username: 'fake.supervisor', fullName: 'Fake Supervisor');

ReceivedDevice createFakeDevice({
  String? id = 'fake-device-id',
  String serialNumber = 'SN-FAKE-0001',
  bool battery = true,
  bool chargerCable = true,
  bool chargerHead = true,
  bool hasSim = false,
  String inventoryType = 'fixed',
  String? status = 'approved',
}) {
  return ReceivedDevice(
    id: id,
    serialNumber: serialNumber,
    battery: battery,
    chargerCable: chargerCable,
    chargerHead: chargerHead,
    hasSim: hasSim,
    inventoryType: inventoryType,
    status: status,
  );
}

/// A fake warehouse shape matching the `Map<String,String>` convention used
/// throughout the app's dashboard/handover controllers (no dedicated
/// Warehouse entity class exists client-side — the backend's `warehouses`
/// table is consumed here as a loosely-typed map, so the fake matches that).
Map<String, String> createFakeWarehouse({
  String id = 'fake-warehouse-id',
  String name = 'Fake Warehouse',
  String city = 'Riyadh',
}) {
  return {'id': id, 'name': name, 'city': city};
}

CourierRequest createFakeCourierRequest({
  int id = 1,
  String? tid = 'TID-FAKE-0001',
  String? installationType = 'new',
  int version = 1,
}) {
  return CourierRequest(id: id, tid: tid, installationType: installationType, version: version);
}

/// A fake successful Dio Response — the shape ApiClient.get/post/put/delete
/// return, and every repository implementation unwraps `.data` from.
Response<dynamic> createFakeApiResponse({
  dynamic data,
  int statusCode = 200,
  String path = '/fake/path',
}) {
  return Response(
    data: data,
    statusCode: statusCode,
    requestOptions: RequestOptions(path: path),
  );
}

/// A fake DioException — for error-state smoke tests (no real network call).
DioException createFakeApiError({
  int statusCode = 500,
  String path = '/fake/path',
  DioExceptionType type = DioExceptionType.badResponse,
}) {
  final options = RequestOptions(path: path);
  return DioException(
    requestOptions: options,
    type: type,
    response: Response(statusCode: statusCode, requestOptions: options),
  );
}

/// Represents the two states the app's UI reasons about ("has queued
/// offline items" vs not) — there is no real connectivity_plus-style
/// plugin in this codebase (confirmed absent from pubspec.yaml); the app's
/// actual offline signal is the presence of queued items in
/// OfflineQueueRepository, not a live network-status stream. This fake
/// models THAT real signal, not an invented one.
enum FakeConnectivityStatus { online, offline }

/// A fake scanner result — the barcode STRING a real scan would ultimately
/// yield. The scanner subsystem (BarcodeCandidateSelector,
/// ScannerSessionManager, BarcodeValidationEngine — see
/// test/scanner/scanner_pipeline_test.dart) already operates purely on
/// strings, camera-agnostic by design; this fake is that same string, used
/// to smoke-test the pipeline without a camera, not a new abstraction.
String createFakeScannedBarcode({String serial = 'SN-FAKE-SCAN-0001'}) => serial;
