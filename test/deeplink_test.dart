import 'package:deeplinks/logic/deeplink.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('inspects scheme, host, path and repeated query params', () {
    final i = inspectLink('https://example.com/a/b%20c?x=1&x=2&y=hi%21#top');
    expect(i.isValid, isTrue);
    expect(i.scheme, 'https');
    expect(i.host, 'example.com');
    expect(i.pathSegments, ['a', 'b c']);
    expect(i.query, {
      'x': ['1', '2'],
      'y': ['hi!'],
    });
    expect(i.fragment, 'top');
    expect(i.warnings, isEmpty);
  });

  test('custom scheme links are fine', () {
    final i = inspectLink('myapp://product/42?ref=home');
    expect(i.scheme, 'myapp');
    expect(i.host, 'product');
    expect(i.pathSegments, ['42']);
    expect(i.warnings, isEmpty);
  });

  test('flags missing scheme, http and whitespace', () {
    expect(inspectLink('').warnings, ['Enter a link to inspect']);
    expect(inspectLink('example.com/x').warnings.single, contains('scheme'));
    expect(
        inspectLink('http://example.com').warnings.single, contains('https'));
    expect(
      inspectLink('https://example.com/a b').warnings,
      contains(contains('whitespace')),
    );
  });

  test('buildLink encodes path and params', () {
    expect(
      buildLink(
        scheme: 'MyApp',
        host: 'product',
        path: '/42/details/',
        params: const [MapEntry('ref', 'summer sale'), MapEntry('a&b', '=')],
      ),
      'myapp://product/42/details?ref=summer+sale&a%26b=%3D',
    );
    expect(buildLink(scheme: 'https', host: 'x.com'), 'https://x.com');
    expect(
      buildLink(
          scheme: 'https', host: 'x.com', params: const [MapEntry(' ', 'v')]),
      'https://x.com',
    );
  });

  test('buildLink rejects invalid schemes', () {
    expect(() => buildLink(scheme: '1abc'), throwsFormatException);
    expect(() => buildLink(scheme: ''), throwsFormatException);
  });

  test('round trip: built link inspects back to its parts', () {
    final link = buildLink(
      scheme: 'myapp',
      host: 'open',
      path: 'a b',
      params: const [MapEntry('q', 'x y&z')],
    );
    final i = inspectLink(link);
    expect(i.pathSegments, ['a b']);
    expect(i.query['q'], ['x y&z']);
  });
}
