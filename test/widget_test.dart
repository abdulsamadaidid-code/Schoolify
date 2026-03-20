import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:schoolify_app/app/app.dart';

void main() {
  testWidgets('SchoolifyApp builds', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: SchoolifyApp()));
    await tester.pump();
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
