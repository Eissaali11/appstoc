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

  testWidgets('confirm button stays disabled until the serial is typed exactly',
      (tester) async {
    var confirmCalls = 0;
    await pumpDialog(tester, onConfirmDelete: () async {
      confirmCalls++;
    });

    final confirmButtonFinder = find.widgetWithText(ElevatedButton, 'تأكيد الحذف النهائي');
    expect(confirmButtonFinder, findsOneWidget);
    expect(tester.widget<ElevatedButton>(confirmButtonFinder).onPressed, isNull);

    await tester.enterText(find.byType(TextField), 'wrong-value');
    await tester.pump();
    expect(tester.widget<ElevatedButton>(confirmButtonFinder).onPressed, isNull);

    await tester.enterText(find.byType(TextField), serial);
    await tester.pump();
    expect(tester.widget<ElevatedButton>(confirmButtonFinder).onPressed, isNotNull);

    expect(confirmCalls, 0);
  });

  testWidgets('tapping confirm calls onConfirmDelete exactly once and closes with true on success',
      (tester) async {
    var confirmCalls = 0;
    await pumpDialog(tester, onConfirmDelete: () async {
      confirmCalls++;
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });

    await tester.enterText(find.byType(TextField), serial);
    await tester.pump();

    // There is only one ElevatedButton in this dialog (the confirm button) —
    // its child swaps to a loading spinner once submitting, so we address it
    // by type rather than by its (disappearing) text.
    final confirmButtonFinder = find.byType(ElevatedButton).last;
    await tester.tap(confirmButtonFinder);
    // Loading indicator should appear immediately, buttons disabled — try tapping again.
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.tap(confirmButtonFinder); // should be a no-op (disabled / already submitting)
    await tester.tap(confirmButtonFinder);

    await tester.pumpAndSettle();

    // Only a single delete request should ever have been made, despite repeated taps.
    expect(confirmCalls, 1);
    // Dialog should have closed itself (popped) after success.
    expect(find.byType(TextField), findsNothing);
  });

  testWidgets('stays open and shows the error message when the delete fails',
      (tester) async {
    await pumpDialog(tester, onConfirmDelete: () async {
      throw Exception('لا يمكنك حذف رقم تسلسلي غير موجود في عهدتك');
    });

    await tester.enterText(find.byType(TextField), serial);
    await tester.pump();

    await tester.tap(find.widgetWithText(ElevatedButton, 'تأكيد الحذف النهائي'));
    await tester.pumpAndSettle();

    // Dialog must remain open (not silently closed) and must surface the error.
    expect(find.byType(TextField), findsOneWidget);
    expect(find.textContaining('لا يمكنك حذف رقم تسلسلي غير موجود في عهدتك'), findsOneWidget);
  });

  testWidgets('cancel button is disabled while a delete request is in flight',
      (tester) async {
    await pumpDialog(tester, onConfirmDelete: () async {
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });

    await tester.enterText(find.byType(TextField), serial);
    await tester.pump();
    await tester.tap(find.widgetWithText(ElevatedButton, 'تأكيد الحذف النهائي'));
    await tester.pump();

    final cancelButtonFinder = find.widgetWithText(OutlinedButton, 'إلغاء');
    expect(tester.widget<OutlinedButton>(cancelButtonFinder).onPressed, isNull);

    await tester.pumpAndSettle();
  });
}
