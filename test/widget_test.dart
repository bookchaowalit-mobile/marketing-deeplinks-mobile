import 'package:deeplinks/main.dart';
import 'package:deeplinks/screens/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  Widget home({double textScale = 1}) => MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
          child: const HomeScreen(),
        ),
      );

  testWidgets('copy puts the built link on the clipboard', (tester) async {
    String? copied;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copied = (call.arguments as Map)['text'] as String;
        }
        return null;
      },
    );
    await tester.pumpWidget(home());
    await tester.scrollUntilVisible(
      find.byKey(const Key('copy-link')),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byKey(const Key('copy-link')));
    await tester.pump();
    expect(copied, 'myapp://product/42?ref=summer+sale');
    expect(find.text('Link copied'), findsOneWidget);
  });

  testWidgets('copy is disabled and host errors are readable', (tester) async {
    await tester.pumpWidget(home());
    await tester.scrollUntilVisible(
      find.byKey(const Key('copy-link')),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.enterText(find.byKey(const Key('host-input')), 'a/b');
    await tester.pump();
    expect(
      tester.widget<SelectableText>(find.byKey(const Key('built-link'))).data,
      startsWith('Error: Host may only contain'),
    );
    expect(
      tester.widget<IconButton>(find.byKey(const Key('copy-link'))).onPressed,
      isNull,
    );
  });

  testWidgets('empty link shows the prompt instead of details', (
    tester,
  ) async {
    await tester.pumpWidget(home());
    await tester.enterText(find.byKey(const Key('link-input')), '');
    await tester.pump();
    expect(find.text('Enter a link to inspect'), findsOneWidget);
    expect(find.text('Path segments'), findsNothing);
  });

  testWidgets('meets tap-target, label and contrast guidelines', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(home());
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    await expectLater(tester, meetsGuideline(textContrastGuideline));
    handle.dispose();
  });

  testWidgets('lays out at 200% text scale on a phone without overflow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 740);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(home(textScale: 2));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
