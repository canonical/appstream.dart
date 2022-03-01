/// Types of URLs for components.
enum AppstreamUrlType {
  homepage,
  bugtracker,
  faq,
  help,
  donation,
  translate,
  contact
}

/// A URL for more information about an Appstream component.
class AppstreamUrl {
  /// The type of URL.
  final AppstreamUrlType type;

  /// The URL, e.g. 'https://example.com/help'.
  final String url;

  const AppstreamUrl(this.url, {required this.type});

  @override
  bool operator ==(other) =>
      other is AppstreamUrl && other.type == type && other.url == url;

  @override
  int get hashCode => Object.hash(type, url);

  @override
  String toString() => '$runtimeType($url, type: $type)';
}
