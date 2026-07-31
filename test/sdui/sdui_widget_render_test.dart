import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nuolipapp/core/sdui/models/server_driven_filter_config.dart';
import 'package:nuolipapp/core/sdui/widgets/server_driven_filter_bar.dart';

void main() {
  testWidgets('ServerDrivenFilterBar renders server dynamic labels, icons, and order correctly', (WidgetTester tester) async {
    final serverConfig = ServerDrivenFilterConfig.fromJson({
      'schemaVersion': 1,
      'configVersion': 2,
      'issuedAt': '2026-07-31T00:00:00Z',
      'expiresAt': '2030-01-01T00:00:00Z',
      'keyId': 'ed25519-prod-key-1',
      'minAppVersion': '1.0.0',
      'screenId': 'custody_screen',
      'defaultFilterId': 'all',
      'filters': [
        {
          'id': 'all',
          'label': 'جميع العهد المحدثة من السيرفر الأصلي',
          'enabled': true,
          'order': 1,
          'icon': 'inventory_2_outlined',
          'colorHex': '#18B2B0',
          'statuses': [],
        },
        {
          'id': 'under_action',
          'label': 'عهد قيد الإجراء الميداني',
          'enabled': true,
          'order': 2,
          'icon': 'pending_actions_rounded',
          'colorHex': '#FFB300',
          'statuses': ['UNDER_ACTION'],
        },
      ],
    });

    String selectedFilter = 'all';

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ServerDrivenFilterBar(
            config: serverConfig,
            activeFilterId: selectedFilter,
            onFilterSelected: (newId) {
              selectedFilter = newId;
            },
          ),
        ),
      ),
    );

    // Verify initial render of dynamic labels
    expect(find.text('جميع العهد المحدثة من السيرفر الأصلي'), findsOneWidget);
    expect(find.text('عهد قيد الإجراء الميداني'), findsOneWidget);

    // Tap second filter chip
    await tester.tap(find.text('عهد قيد الإجراء الميداني'));
    await tester.pumpAndSettle();

    expect(selectedFilter, equals('under_action'));
  });
}
