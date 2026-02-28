// اختبارات ويدجت: التحقق من أن المكونات المشتركة تُبنى بشكل صحيح.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nuolipapp/shared/widgets/empty_state.dart';

void main() {
  testWidgets('EmptyState يعرض الرسالة والأيقونة', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: EmptyState(message: 'لا توجد بيانات'),
        ),
      ),
    );

    expect(find.text('لا توجد بيانات'), findsOneWidget);
    expect(find.byIcon(Icons.inbox_outlined), findsOneWidget);
  });

  testWidgets('EmptyState يقبل أيقونة مخصصة', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: EmptyState(
            message: 'فارغ',
            icon: Icons.search_off,
          ),
        ),
      ),
    );

    expect(find.text('فارغ'), findsOneWidget);
    expect(find.byIcon(Icons.search_off), findsOneWidget);
  });
}
