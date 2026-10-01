/// Pure helpers to inspect and build deep links.
library;

class LinkInspection {
  const LinkInspection({
    required this.uri,
    required this.scheme,
    required this.host,
    required this.pathSegments,
    required this.query,
    required this.fragment,
    required this.warnings,
  });

  final Uri? uri;
  final String scheme;
  final String host;
  final List<String> pathSegments;
  final Map<String, List<String>> query;
  final String fragment;
  final List<String> warnings;

  bool get isValid => uri != null;
}

/// Parses [input] and reports common deep-link problems.
LinkInspection inspectLink(String input) {
  final raw = input.trim();
  final warnings = <String>[];
  if (raw.isEmpty) {
    return const LinkInspection(
      uri: null,
      scheme: '',
      host: '',
      pathSegments: [],
      query: {},
      fragment: '',
      warnings: ['Enter a link to inspect'],
    );
  }
  if (raw.contains(RegExp(r'\s'))) {
    warnings.add('Contains whitespace; encode spaces as %20');
  }
  final uri = Uri.tryParse(raw);
  if (uri == null) {
    return LinkInspection(
      uri: null,
      scheme: '',
      host: '',
      pathSegments: const [],
      query: const {},
      fragment: '',
      warnings: [...warnings, 'Not a valid URI'],
    );
  }
  if (!uri.hasScheme) {
    warnings.add('Missing scheme (e.g. https:// or myapp://)');
  } else if (uri.scheme == 'http') {
    warnings.add(
      'Android App Links and iOS Universal Links require https, not http',
    );
  }
  if (uri.hasScheme &&
      (uri.scheme == 'http' || uri.scheme == 'https') &&
      uri.host.isEmpty) {
    warnings.add('Web links need a host');
  }
  // Dart's Uri keeps malformed escapes such as `%zz` literally instead of
  // throwing, so check the raw text for them explicitly.
  final badEscape = RegExp(r'%(?![0-9A-Fa-f]{2})');
  final queryStart = raw.indexOf('?');
  final fragmentStart = raw.indexOf('#');
  final pathEnd = [queryStart, fragmentStart, raw.length]
      .where((i) => i >= 0)
      .reduce((a, b) => a < b ? a : b);
  if (badEscape.hasMatch(raw.substring(0, pathEnd))) {
    warnings.add('Path has invalid percent-encoding');
  }
  if (queryStart >= 0) {
    final queryEnd = fragmentStart > queryStart ? fragmentStart : raw.length;
    if (badEscape.hasMatch(raw.substring(queryStart, queryEnd))) {
      warnings.add('Query string has invalid percent-encoding');
    }
  }
  Map<String, List<String>> query;
  try {
    query = uri.queryParametersAll;
  } on FormatException {
    query = const {};
    warnings.add('Query string has invalid percent-encoding');
  }
  List<String> segments;
  try {
    segments = uri.pathSegments;
  } on FormatException {
    segments = const [];
    warnings.add('Path has invalid percent-encoding');
  }
  return LinkInspection(
    uri: uri,
    scheme: uri.scheme,
    host: uri.host,
    pathSegments: segments,
    query: query,
    fragment: uri.fragment,
    warnings: warnings,
  );
}

final _schemePattern = RegExp(r'^[a-zA-Z][a-zA-Z0-9+.-]*$');

/// Registered name (letters, digits, `-`, `.`, `_`, `~` or any non-ASCII
/// character for IDNs) with an optional `:port`.
final _hostPattern =
    RegExp(r'^([A-Za-z0-9\-._~\u0080-\uFFFF]*)(?::([0-9]{1,5}))?$');

/// Schemes whose links have no `//authority` part (`mailto:a@b.com`).
const _opaqueSchemes = {'mailto', 'tel', 'sms', 'geo'};

/// Builds a link from parts; empty param keys are skipped.
/// Throws [FormatException] for an invalid scheme.
String buildLink({
  required String scheme,
  String host = '',
  String path = '',
  List<MapEntry<String, String>> params = const [],
}) {
  final s = scheme.trim();
  if (!_schemePattern.hasMatch(s)) {
    throw const FormatException('Scheme must start with a letter');
  }
  final hostMatch = _hostPattern.firstMatch(host.trim());
  if (hostMatch == null) {
    throw const FormatException(
      'Host may only contain letters, digits, "-", "." and an optional :port',
    );
  }
  final hostName = hostMatch.group(1)!;
  final portText = hostMatch.group(2);
  final port = portText == null ? null : int.parse(portText);
  if (port != null && (port < 1 || port > 65535)) {
    throw const FormatException('Port must be between 1 and 65535');
  }
  if (port != null && hostName.isEmpty) {
    throw const FormatException('A port needs a host');
  }
  final segments =
      path.split('/').map((p) => p.trim()).where((p) => p.isNotEmpty).toList();
  final filtered = params.where((e) => e.key.trim().isNotEmpty).toList();
  final query = filtered.isEmpty
      ? null
      : filtered
          .map(
            (e) => '${Uri.encodeQueryComponent(e.key.trim())}='
                '${Uri.encodeQueryComponent(e.value)}',
          )
          .join('&');
  final lower = s.toLowerCase();
  if (hostName.isEmpty && _opaqueSchemes.contains(lower)) {
    return Uri(
      scheme: lower,
      // Keep `@` and `+` readable (`mailto:a+b@x.com`, `tel:+66...`); both
      // are legal in a URI path.
      path: segments
          .map(
            (p) => Uri.encodeComponent(p)
                .replaceAll('%40', '@')
                .replaceAll('%2B', '+'),
          )
          .join('/'),
      query: query,
    ).toString();
  }
  final uri = Uri(
    scheme: lower,
    host: hostName,
    port: port,
    pathSegments: segments,
    query: query,
  );
  return uri.toString();
}
