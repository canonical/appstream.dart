/// Metadata about an icon.
class AppstreamIcon {
  const AppstreamIcon();
}

/// Metadata for an icon in the stock set.
class AppstreamStockIcon extends AppstreamIcon {
  const AppstreamStockIcon(this.name);

  /// The name of the icon, e.g. 'firefox'.
  final String name;

  @override
  bool operator ==(Object other) =>
      other is AppstreamStockIcon && other.name == name;

  @override
  int get hashCode => name.hashCode;

  @override
  String toString() => "$runtimeType('$name')";
}

/// Metadata for an icon installed in the icon cache.
class AppstreamCachedIcon extends AppstreamIcon {
  const AppstreamCachedIcon(this.name, {this.width, this.height});

  /// Name of the icon, e.g. 'firefox.png'.
  final String name;

  /// Width of the icon in pixels.
  final int? width;

  /// Height of the icon in pixels.
  final int? height;

  @override
  bool operator ==(Object other) =>
      other is AppstreamCachedIcon &&
      other.name == name &&
      other.width == width &&
      other.height == height;

  @override
  int get hashCode => Object.hash(name, width, height);

  @override
  String toString() => "$runtimeType('$name', width: $width, height: $height)";
}

/// Metadata for an icon installed on the local system.
class AppstreamLocalIcon extends AppstreamIcon {
  const AppstreamLocalIcon(this.filename, {this.width, this.height});

  /// The file containing the icon, e.g. '/usr/share/my_app/my_icon.png'.
  final String filename;

  /// Width of the icon in pixels.
  final int? width;

  /// Height of the icon in pixels.
  final int? height;

  @override
  bool operator ==(Object other) =>
      other is AppstreamLocalIcon &&
      other.filename == filename &&
      other.width == width &&
      other.height == height;

  @override
  int get hashCode => Object.hash(filename, width, height);

  @override
  String toString() =>
      "$runtimeType('$filename', width: $width, height: $height)";
}

/// Metadata for an icon accessed via a URL.
class AppstreamRemoteIcon extends AppstreamIcon {
  const AppstreamRemoteIcon(this.url, {this.width, this.height});

  /// The URL for the icon file. e.g. 'https://example.com/my_icon.png'
  final String url;

  /// Width of the icon in pixels.
  final int? width;

  /// Height of the icon in pixels.
  final int? height;

  @override
  bool operator ==(Object other) =>
      other is AppstreamRemoteIcon &&
      other.url == url &&
      other.width == width &&
      other.height == height;

  @override
  int get hashCode => Object.hash(url, width, height);

  @override
  String toString() => "$runtimeType('$url', width: $width, height: $height)";
}
