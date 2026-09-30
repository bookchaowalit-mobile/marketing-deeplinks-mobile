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
  final segments =
      path.split('/').map((p) => p.trim()).where((p) => p.isNotEmpty).toList();
  final filtered = params.where((e) => e.key.trim().isNotEmpty).toList();
  final uri = Uri(
    scheme: s.toLowerCase(),
    host: host.trim(),
    pathSegments: segments,
    query: filtered.isEmpty
        ? null
        : filtered
            .map(
              (e) => '${Uri.encodeQueryComponent(e.key.trim())}='
                  '${Uri.encodeQueryComponent(e.value)}',
            )
            .join('&'),
  );
  return uri.toString();
}
