class AppstreamIcon {
  const AppstreamIcon();
}

class AppstreamStockIcon extends AppstreamIcon {
  final String name;

  const AppstreamStockIcon(this.name);

  @override
  bool operator ==(other) => other is AppstreamStockIcon && other.name == name;

  @override
  String toString() => "$runtimeType('$name')";
}

class AppstreamCachedIcon extends AppstreamIcon {
  final String name;
  final int? width;
  final int? height;

  const AppstreamCachedIcon(this.name, {this.width, this.height});

  @override
  bool operator ==(other) =>
      other is AppstreamCachedIcon &&
      other.name == name &&
      other.width == width &&
      other.height == height;

  @override
  String toString() => "$runtimeType('$name', width: $width, height: $height)";
}

class AppstreamLocalIcon extends AppstreamIcon {
  final String filename;
  final int? width;
  final int? height;

  const AppstreamLocalIcon(this.filename, {this.width, this.height});

  @override
  bool operator ==(other) =>
      other is AppstreamLocalIcon &&
      other.filename == filename &&
      other.width == width &&
      other.height == height;

  @override
  String toString() =>
      "$runtimeType('$filename', width: $width, height: $height)";
}

class AppstreamRemoteIcon extends AppstreamIcon {
  final String url;
  final int? width;
  final int? height;

  const AppstreamRemoteIcon(this.url, {this.width, this.height});

  @override
  bool operator ==(other) =>
      other is AppstreamRemoteIcon &&
      other.url == url &&
      other.width == width &&
      other.height == height;

  @override
  String toString() => "$runtimeType('$url', width: $width, height: $height)";
}
