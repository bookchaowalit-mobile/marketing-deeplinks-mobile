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

  group('edge cases (pass 3)', () {
    test('flags malformed percent-escapes that Uri silently keeps', () {
      expect(
        inspectLink('https://x.com/a%zz').warnings,
        contains('Path has invalid percent-encoding'),
      );
      expect(
        inspectLink('https://x.com/?q=%2').warnings,
        contains('Query string has invalid percent-encoding'),
      );
      expect(inspectLink('https://x.com/a%20b?q=%C3%A9#%zz').warnings, isEmpty);
    });

    test('empty, whitespace-only and unparsable input', () {
      expect(inspectLink('   ').isValid, isFalse);
      expect(inspectLink('   ').warnings, ['Enter a link to inspect']);
      expect(inspectLink('https://[::1').isValid, isFalse);
      expect(inspectLink('HTTPS://X.COM').scheme, 'https');
      expect(inspectLink('https:x.com').warnings,
          contains('Web links need a host'));
    });

    test('buildLink supports host:port and rejects bad hosts', () {
      expect(
        buildLink(scheme: 'https', host: 'example.com:8080', path: 'a'),
        'https://example.com:8080/a',
      );
      for (final bad in [
        'my host',
        'a/b',
        'x.com:0',
        'x.com:70000',
        ':80',
        'x.com:'
      ]) {
        expect(
          () => buildLink(scheme: 'https', host: bad),
          throwsFormatException,
          reason: bad,
        );
      }
    });

    test('mailto/tel links have no authority', () {
      expect(
        buildLink(
          scheme: 'mailto',
          path: 'a+b@x.com',
          params: const [MapEntry('subject', 'a+b there')],
        ),
        'mailto:a+b@x.com?subject=a%2Bb+there',
      );
      expect(
          buildLink(scheme: 'tel', path: '+66812345678'), 'tel:+66812345678');
      expect(buildLink(scheme: 'myapp', path: 'a/b'), 'myapp:///a/b');
    });

    test('unicode path and params round trip', () {
      final link = buildLink(
        scheme: 'https',
        host: 'shop.example',
        path: 'สินค้า/😀',
        params: const [MapEntry('q', 'ชา เย็น&x=1')],
      );
      expect(link, isNot(contains(' ')));
      final i = inspectLink(link);
      expect(i.warnings, isEmpty);
      expect(i.pathSegments, ['สินค้า', '😀']);
      expect(i.query['q'], ['ชา เย็น&x=1']);
    });
  });
}
