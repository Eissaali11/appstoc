import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nuolipapp/features/moving_inventory/presentation/pages/shipment_scan_page.dart';
import 'package:nuolipapp/shared/scanner/explicit_selection_scan.dart';

/// Page-level wiring proof for the final explicit-selection rule, driving the
/// REAL `ShipmentScanPage` (real dropdown, real text field, real add/save
/// buttons) against a fake Dio adapter that serves the item-type catalog and
/// captures the actual POST body. The server itself is not involved.
class _FakeAdapter implements HttpClientAdapter {
  final List<Map<String, dynamic>> catalog;
  final List<RequestOptions> posts = [];
  _FakeAdapter(this.catalog);

  ResponseBody _json(Object body) => ResponseBody.fromString(
        jsonEncode(body),
        200,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );

  @override
  Future<ResponseBody> fetch(RequestOptions options,
      Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    if (options.method == 'POST' &&
        options.path.contains('/api/serialized-items/batch-scan-in')) {
      posts.add(options);
      return _json({'addedCount': 99, 'rejectedCount': 0});
    }
    if (options.path.contains('/api/item-types/active')) {
      return _json(catalog);
    }
    return _json(<dynamic>[]); // custody lists etc.
  }

  @override
  void close({bool force = false}) {}
}

Map<String, dynamic> _device(String id, int sort, String prefix, int len,
        String regex) =>
    {
      'id': id,
      'nameEn': id,
      'nameAr': id,
      'sortOrder': sort,
      'isActive': true,
      'isVisible': true,
      'category': 'devices',
      'requiresSerial': true,
      'serialPrefix': prefix,
      'serialLength': len,
      'serialRegex': regex,
    };

void main() {
  late _FakeAdapter adapter;

  setUp(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    Get.reset();
    adapter = _FakeAdapter([
      _device('n950', 1, 'NCC,NCD', 12, r'^(NCC|NCD)[0-9]{9}$'), // first/default
      _device('i9100', 2, 'SAW', 11, r'^SAW[0-9]{8}$'),
      _device('i9000s', 3, 'SAS', 11, r'^SAS[0-9]{8}$'),
    ]);
    final dio = Dio(BaseOptions(baseUrl: 'http://fake'))
      ..httpClientAdapter = adapter;
    Get.put<Dio>(dio);
  });

  tearDown(Get.reset);

  Future<void> pumpPage(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 2600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(GetMaterialApp(home: const ShipmentScanPage()));
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }
  }

  Future<void> typeSerialAndAdd(WidgetTester tester, String serial) async {
    await tester.enterText(find.byType(TextFormField).first, serial);
    await tester.pump();
    await tester.tap(find.text('إضافة للقائمة المؤقتة (+)').first);
    for (var i = 0; i < 4; i++) {
      await tester.pump(const Duration(milliseconds: 150));
    }
  }

  Future<void> pickType(WidgetTester tester, String nameAr) async {
    await tester.tap(find.byType(DropdownButton<String>).first);
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.text(nameAr).last);
    await tester.pump(const Duration(milliseconds: 400));
  }

  testWidgets(
      'page: without an explicit pick the scan is BLOCKED with the prompt and '
      'nothing is saved; a rejected number names the selected type', (tester) async {
    await pumpPage(tester);

    // The dropdown shows the auto-defaulted first item (n950), which does NOT
    // count as a selection: a perfectly valid N950 serial is blocked.
    await typeSerialAndAdd(tester, 'NCD100232013');
    expect(find.text(kExplicitSelectionRequiredMessage), findsOneWidget);
    expect(adapter.posts, isEmpty);

    // Now pick i9100 deliberately and enter a serial that belongs to another
    // type: rejected with an error NAMING i9100; nothing offered instead.
    await pickType(tester, 'i9100');
    await typeSerialAndAdd(tester, 'NCD100232013');
    expect(find.textContaining('"i9100"'), findsOneWidget);
    expect(find.text(kExplicitSelectionRequiredMessage), findsNothing);
    expect(adapter.posts, isEmpty);
  });

  testWidgets(
      'page: type A, explicit switch to B, scan again, ONE save → the real '
      'POST body keeps each item\'s own itemTypeId', (tester) async {
    await pumpPage(tester);

    // ItemType sanitizes the display name of id `n950` to "N950".
    await pickType(tester, 'N950'); // deliberate pick of the (same) first item
    await typeSerialAndAdd(tester, 'NCD100232013');

    await pickType(tester, 'i9100'); // explicit switch
    await typeSerialAndAdd(tester, 'SAW12345678');

    await tester.tap(find.text('حفظ القائمة بالكامل في النظام ✓').first);
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }

    expect(adapter.posts.length, 1);
    final body = adapter.posts.single.data as Map<String, dynamic>;
    final items = (body['items'] as List).cast<Map<String, dynamic>>();
    expect(items.map((m) => m['itemTypeId']).toList(), ['n950', 'i9100']);
    expect(items.map((m) => m['serialNumber']).toList(),
        ['NCD100232013', 'SAW12345678']);
    expect(items.any((m) => m.containsKey('carrierName')), isFalse);
  });
}
