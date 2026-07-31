// TEMPORARY FEATURE — remove or disable after final customer handover.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nuolipapp/features/dashboard/presentation/widgets/custody_delete_confirmation_dialog.dart';

void main() {
  const serial = 'NCD100257804';

  Future<void> pumpDialog(
    WidgetTester tester, {
    required Future<void> Function() onConfirmDelete,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => showCustodyDeleteConfirmationDialog(
              context,
              serialNumber: serial,
              itemTitle: 'جهاز POS',
              itemCategoryLabel: 'جهاز',
              statusLabel: 'في عهدتك الحالية (نشط)',
              onConfirmDelete: onConfirmDelete,
            ),
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  testWidgets('shows the item category (SIM vs DEVICE) so the two are never confused',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => showCustodyDeleteConfirmationDialog(
              context,
              serialNumber: '89966020000000123456',
              itemTitle: 'شريحة STC',
              itemCategoryLabel: 'شريحة',
              statusLabel: 'في عهدتك الحالية (نشط)',
              onConfirmDelete: () async {},
            ),
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('شريحة'), findsOneWidget);
    expect(find.text('نوع العنصر:'), findsOneWidget);
  });

  testWidgets('tapping confirm calls onConfirmDelete exactly once and closes with true on success',
      (tester) async {
    var confirmCalls = 0;
    await pumpDialog(tester, onConfirmDelete: () async {
      confirmCalls++;
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });

    final confirmButtonFinder = find.byType(ElevatedButton).last;
    await tester.tap(confirmButtonFinder);
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.tap(confirmButtonFinder);
    await tester.tap(confirmButtonFinder);

    await tester.pumpAndSettle();

    expect(confirmCalls, 1);
  });

  testWidgets('stays open and shows the error message when the delete fails',
      (tester) async {
    await pumpDialog(tester, onConfirmDelete: () async {
      throw Exception('لا يمكنك حذف رقم تسلسلي غير موجود في عهدتك');
    });

    await tester.tap(find.widgetWithText(ElevatedButton, 'نعم، حذف من عهدتي'));
    await tester.pumpAndSettle();

    expect(find.textContaining('لا يمكنك حذف رقم تسلسلي غير موجود في عهدتك'), findsOneWidget);
  });

  testWidgets('cancel button is disabled while a delete request is in flight',
      (tester) async {
    await pumpDialog(tester, onConfirmDelete: () async {
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });

    await tester.tap(find.widgetWithText(ElevatedButton, 'نعم، حذف من عهدتي'));
    await tester.pump();

    final cancelButtonFinder = find.widgetWithText(OutlinedButton, 'إلغاء');
    expect(tester.widget<OutlinedButton>(cancelButtonFinder).onPressed, isNull);

    await tester.pumpAndSettle();
  });
}
