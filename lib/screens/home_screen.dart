import 'package:flutter/material.dart';

import '../logic/deeplink.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _input = TextEditingController(
    text: 'https://example.com/products/42?ref=app&utm_source=mail',
  );
  final _scheme = TextEditingController(text: 'myapp');
  final _host = TextEditingController(text: 'product');
  final _path = TextEditingController(text: '42');
  final _key = TextEditingController(text: 'ref');
  final _value = TextEditingController(text: 'summer sale');

  @override
  void dispose() {
    for (final c in [_input, _scheme, _host, _path, _key, _value]) {
      c.dispose();
    }
    super.dispose();
  }

  String _built() {
    try {
      return buildLink(
        scheme: _scheme.text,
        host: _host.text,
        path: _path.text,
        params: [MapEntry(_key.text, _value.text)],
      );
    } on FormatException catch (e) {
      return 'Error: ${e.message}';
    }
  }

  Widget _field(TextEditingController c, String label, String key) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: TextField(
        key: Key(key),
        controller: c,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        onChanged: (_) => setState(() {}),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final info = inspectLink(_input.text);
    return Scaffold(
      appBar: AppBar(title: const Text('Deeplinks')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Inspect a link', style: textTheme.titleMedium),
          const SizedBox(height: 8),
          _field(_input, 'Link', 'link-input'),
          if (info.isValid)
            Card(
              child: Column(
                children: [
                  ListTile(
                    title: const Text('Scheme'),
                    subtitle: Text(info.scheme.isEmpty ? '—' : info.scheme),
                  ),
                  ListTile(
                    title: const Text('Host'),
                    subtitle: Text(info.host.isEmpty ? '—' : info.host),
                  ),
                  ListTile(
                    title: const Text('Path segments'),
                    subtitle: Text(
                      info.pathSegments.isEmpty
                          ? '—'
                          : info.pathSegments.join(' / '),
                    ),
                  ),
                  for (final e in info.query.entries)
                    ListTile(
                      dense: true,
                      title: Text(e.key),
                      subtitle: Text(e.value.join(', ')),
                    ),
                ],
              ),
            ),
          for (final w in info.warnings)
            ListTile(
              leading: Icon(
                Icons.warning_amber,
                color: Theme.of(context).colorScheme.error,
              ),
              title: Text(w),
            ),
          const SizedBox(height: 24),
          Text('Build a link', style: textTheme.titleMedium),
          const SizedBox(height: 8),
          _field(_scheme, 'Scheme', 'scheme-input'),
          _field(_host, 'Host', 'host-input'),
          _field(_path, 'Path', 'path-input'),
          Row(
            children: [
              Expanded(child: _field(_key, 'Param key', 'key-input')),
              const SizedBox(width: 8),
              Expanded(child: _field(_value, 'Param value', 'value-input')),
            ],
          ),
          SelectableText(
            _built(),
            key: const Key('built-link'),
            style: textTheme.titleSmall,
          ),
        ],
      ),
    );
  }
}
