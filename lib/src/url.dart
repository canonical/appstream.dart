/// Types of URLs for components.
enum AppstreamUrlType {
  homepage,
  bugtracker,
  faq,
  help,
  donation,
  translate,
  contact,
  vcsBrowser,
  contribute
}

/// A URL for more information about an Appstream component.
class AppstreamUrl {
  const AppstreamUrl(this.url, {required this.type});

  /// The type of URL.
  final AppstreamUrlType type;

  /// The URL, e.g. 'https://example.com/help'.
  final String url;

  @override
  bool operator ==(Object other) =>
      other is AppstreamUrl && other.type == type && other.url == url;

  @override
  int get hashCode => Object.hash(type, url);

  @override
  String toString() => '$runtimeType($url, type: $type)';
}
