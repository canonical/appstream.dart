import 'package:appstream/src/utils.dart';

/// Types of screenshot image.
enum AppstreamImageType { source, thumbnail }

/// Metadata about an image.
class AppstreamImage {
  const AppstreamImage({
    required this.type,
    required this.url,
    this.width,
    this.height,
    this.lang,
  });

  /// Type of image.
  final AppstreamImageType type;

  /// The URL where this image can be obtained by.
  final String url;

  /// The width of this image in pixels.
  final int? width;

  /// The height of this image in pixels.
  final int? height;

  /// The language this image is intended for.
  final String? lang;

  @override
  bool operator ==(Object other) =>
      other is AppstreamImage &&
      other.type == type &&
      other.url == url &&
      other.width == width &&
      other.height == height &&
      other.lang == lang;

  @override
  int get hashCode => Object.hash(type, url, width, height, lang);

  @override
  String toString() =>
      "$runtimeType(type: $type, url: '$url', width: $width, height: $height, lang: $lang)";
}

/// Metadata for a screenshot of a component.
class AppstreamScreenshot {
  const AppstreamScreenshot({
    this.images = const [],
    this.caption = const {},
    this.isDefault = false,
  });

  /// Images available for this screenshot.
  final List<AppstreamImage> images;

  /// A caption for this screenshot, keyed by language.
  final Map<String, String> caption;

  /// True if this is the default screenshot for this component.
  final bool isDefault;

  @override
  bool operator ==(Object other) =>
      other is AppstreamScreenshot &&
      listsEqual(other.images, images) &&
      mapsEqual(other.caption, caption) &&
      other.isDefault == isDefault;

  @override
  int get hashCode => Object.hash(images, caption, isDefault);

  @override
  String toString() =>
      '$runtimeType(images: $images, caption: $caption, isDefault: $isDefault)';
}
