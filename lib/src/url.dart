enum AppstreamUrlType {
  homepage,
  bugtracker,
  faq,
  help,
  donation,
  translate,
  contact
}

class AppstreamUrl {
  final AppstreamUrlType type;
  final String url;
  const AppstreamUrl(this.url, {required this.type});

  @override
  bool operator ==(other) =>
      other is AppstreamUrl && other.type == type && other.url == url;

  @override
  String toString() => '$runtimeType($url, type: $type)';
}
