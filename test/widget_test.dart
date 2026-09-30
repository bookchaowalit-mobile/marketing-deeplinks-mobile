import 'package:deeplinks/main.dart';
import 'package:deeplinks/screens/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('app shell shows links tool and about tab', (tester) async {
    await tester.pumpWidget(const DeeplinksApp());
    expect(find.text('Deeplinks'), findsWidgets);
    await tester.tap(find.text('About'));
    await tester.pumpAndSettle();
    expect(find.text('Features'), findsOneWidget);
  });

  testWidgets('inspector shows warnings and builder updates', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
    expect(find.text('example.com'), findsOneWidget);
    String built() => tester
        .widget<SelectableText>(find.byKey(const Key('built-link')))
        .data!;

    await tester.enterText(
      find.byKey(const Key('link-input')),
      'http://example.com',
    );
    await tester.pump();
    expect(find.textContaining('require https'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.byKey(const Key('built-link')),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(built(), 'myapp://product/42?ref=summer+sale');
    await tester.enterText(find.byKey(const Key('scheme-input')), '9bad');
    await tester.pump();
    expect(built(), startsWith('Error: Scheme'));
  });
}
