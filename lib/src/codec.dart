import 'dart:convert';
import 'dart:typed_data';

import 'package:appstream/src/bundle.dart';
import 'package:appstream/src/component.dart';
import 'package:appstream/src/icon.dart';
import 'package:appstream/src/language.dart';
import 'package:appstream/src/launchable.dart';
import 'package:appstream/src/provides.dart';
import 'package:appstream/src/release.dart';
import 'package:appstream/src/screenshot.dart';
import 'package:appstream/src/url.dart';

/// Components kept as bytes, each turned back into an object when read.
class EncodedComponents {
  EncodedComponents._(this._bytes, this._recordStarts);

  /// Encodes [components], keeping their order.
  factory EncodedComponents.encode(Iterable<AppstreamComponent> components) {
    final builder = EncodedComponentsBuilder();
    components.forEach(builder.add);
    return builder.build();
  }

  final Uint8List _bytes;

  final Uint32List _recordStarts;

  int get length => _recordStarts.length;

  /// Decodes the component at [index] into a new object on every call.
  AppstreamComponent operator [](int index) =>
      _Reader(_bytes, _recordStarts[index]).component();
}

/// Encodes components as they arrive, so no list of them is ever held.
class EncodedComponentsBuilder {
  final _writer = _Writer();
  final _recordStarts = <int>[];

  void add(AppstreamComponent component) {
    _recordStarts.add(_writer.length);
    _writer.component(component);
  }

  /// Returns everything added so far; the builder must not be used after.
  EncodedComponents build() => EncodedComponents._(
        _writer.takeBytes(),
        Uint32List.fromList(_recordStarts),
      );
}

// A subclass added to the component model must also be added to both classes.
class _Writer {
  var _bytes = Uint8List(64 * 1024);

  int length = 0;

  Uint8List takeBytes() => _bytes.sublist(0, length);

  void _reserve(int extra) {
    if (length + extra <= _bytes.length) {
      return;
    }
    var capacity = _bytes.length * 2;
    while (capacity < length + extra) {
      capacity *= 2;
    }
    _bytes = Uint8List(capacity)..setRange(0, length, _bytes);
  }

  // Seven bits per byte, low bits first; a negative value counts as unsigned.
  void uint(int value) {
    _reserve(10);
    var rest = value;
    while (rest < 0 || rest >= 0x80) {
      _bytes[length++] = (rest & 0x7f) | 0x80;
      rest >>>= 7;
    }
    _bytes[length++] = rest;
  }

  // Zigzag keeps small negative numbers short.
  void integer(int value) => uint((value << 1) ^ (value >> 63));

  void optionalInteger(int? value) {
    uint(value == null ? 0 : 1);
    if (value != null) {
      integer(value);
    }
  }

  void boolean(bool value) => uint(value ? 1 : 0);

  void enumeration(Enum value) => uint(value.index);

  // Lone surrogates become U+FFFD here; catalogs hold valid text.
  void string(String? value) {
    if (value == null) {
      uint(0);
      return;
    }
    final encoded = utf8.encode(value);
    uint(encoded.length + 1);
    _reserve(encoded.length);
    _bytes.setRange(length, length + encoded.length, encoded);
    length += encoded.length;
  }

  void optionalDate(DateTime? value) {
    if (value == null) {
      uint(0);
      return;
    }
    uint(value.isUtc ? 2 : 1);
    integer(value.microsecondsSinceEpoch);
  }

  void list<T>(List<T> items, void Function(T item) write) {
    uint(items.length);
    for (final item in items) {
      write(item);
    }
  }

  void stringMap(Map<String, String> map) {
    uint(map.length);
    map.forEach((key, value) {
      string(key);
      string(value);
    });
  }

  void component(AppstreamComponent component) {
    string(component.id);
    enumeration(component.type);
    string(component.package);
    stringMap(component.name);
    stringMap(component.summary);
    stringMap(component.description);
    stringMap(component.developerName);
    string(component.projectLicense);
    string(component.projectGroup);
    list(component.icons, icon);
    list(component.urls, url);
    list(component.categories, string);
    uint(component.keywords.length);
    component.keywords.forEach((locale, words) {
      string(locale);
      list(words, string);
    });
    list(component.screenshots, screenshot);
    list(component.compulsoryForDesktops, string);
    list(component.releases, release);
    list(component.provides, provides);
    list(component.launchables, launchable);
    list(component.languages, language);
    list(component.bundles, bundle);
    list(component.custom, stringMap);
    uint(component.contentRatings.length);
    component.contentRatings.forEach((system, ratings) {
      string(system);
      uint(ratings.length);
      ratings.forEach((category, rating) {
        string(category);
        enumeration(rating);
      });
    });
  }

  void icon(AppstreamIcon icon) {
    if (icon is AppstreamStockIcon) {
      uint(0);
      string(icon.name);
    } else if (icon is AppstreamCachedIcon) {
      uint(1);
      string(icon.name);
      optionalInteger(icon.width);
      optionalInteger(icon.height);
    } else if (icon is AppstreamLocalIcon) {
      uint(2);
      string(icon.filename);
      optionalInteger(icon.width);
      optionalInteger(icon.height);
    } else if (icon is AppstreamRemoteIcon) {
      uint(3);
      string(icon.url);
      optionalInteger(icon.width);
      optionalInteger(icon.height);
    } else {
      throw ArgumentError.value(icon, 'icon', 'Unknown icon type');
    }
  }

  void url(AppstreamUrl url) {
    string(url.url);
    enumeration(url.type);
  }

  void screenshot(AppstreamScreenshot screenshot) {
    list(screenshot.images, image);
    stringMap(screenshot.caption);
    boolean(screenshot.isDefault);
  }

  void image(AppstreamImage image) {
    enumeration(image.type);
    string(image.url);
    optionalInteger(image.width);
    optionalInteger(image.height);
    string(image.lang);
  }

  void release(AppstreamRelease release) {
    string(release.version);
    optionalDate(release.date);
    enumeration(release.type);
    enumeration(release.urgency);
    stringMap(release.description);
    string(release.url);
    list(release.issues, issue);
  }

  void issue(AppstreamIssue issue) {
    enumeration(issue.type);
    string(issue.id);
    string(issue.url);
  }

  void provides(AppstreamProvides provides) {
    if (provides is AppstreamProvidesMediatype) {
      uint(0);
      string(provides.mediaType);
    } else if (provides is AppstreamProvidesLibrary) {
      uint(1);
      string(provides.libraryName);
    } else if (provides is AppstreamProvidesBinary) {
      uint(2);
      string(provides.binaryName);
    } else if (provides is AppstreamProvidesFont) {
      uint(3);
      string(provides.fontName);
    } else if (provides is AppstreamProvidesModalias) {
      uint(4);
      string(provides.modalias);
    } else if (provides is AppstreamProvidesFirmware) {
      uint(5);
      enumeration(provides.type);
      string(provides.name);
    } else if (provides is AppstreamProvidesPython2) {
      uint(6);
      string(provides.moduleName);
    } else if (provides is AppstreamProvidesPython3) {
      uint(7);
      string(provides.moduleName);
    } else if (provides is AppstreamProvidesDBus) {
      uint(8);
      enumeration(provides.busType);
      string(provides.busName);
    } else if (provides is AppstreamProvidesId) {
      uint(9);
      string(provides.id);
    } else {
      throw ArgumentError.value(provides, 'provides', 'Unknown provides type');
    }
  }

  void launchable(AppstreamLaunchable launchable) {
    if (launchable is AppstreamLaunchableDesktopId) {
      uint(0);
      string(launchable.desktopId);
    } else if (launchable is AppstreamLaunchableService) {
      uint(1);
      string(launchable.serviceName);
    } else if (launchable is AppstreamLaunchableCockpitManifest) {
      uint(2);
      string(launchable.packageName);
    } else if (launchable is AppstreamLaunchableUrl) {
      uint(3);
      string(launchable.url);
    } else {
      throw ArgumentError.value(
        launchable,
        'launchable',
        'Unknown launchable type',
      );
    }
  }

  void language(AppstreamLanguage language) {
    string(language.locale);
    optionalInteger(language.percentage);
  }

  void bundle(AppstreamBundle bundle) {
    string(bundle.id);
    enumeration(bundle.type);
  }
}

class _Reader {
  _Reader(this._bytes, this._position);

  final Uint8List _bytes;
  var _position = 0;

  int uint() {
    var result = 0;
    var shift = 0;
    int byte;
    do {
      byte = _bytes[_position++];
      result |= (byte & 0x7f) << shift;
      shift += 7;
    } while (byte >= 0x80);
    return result;
  }

  int integer() {
    final zigzag = uint();
    return (zigzag >>> 1) ^ -(zigzag & 1);
  }

  int? optionalInteger() => uint() == 0 ? null : integer();

  bool boolean() => uint() != 0;

  String? optionalString() {
    final size = uint();
    if (size == 0) {
      return null;
    }
    final start = _position;
    _position += size - 1;
    return utf8.decoder.convert(_bytes, start, _position);
  }

  String string() => optionalString()!;

  DateTime? optionalDate() {
    final kind = uint();
    if (kind == 0) {
      return null;
    }
    return DateTime.fromMicrosecondsSinceEpoch(integer(), isUtc: kind == 2);
  }

  List<T> list<T>(T Function() read) {
    final length = uint();
    if (length == 0) {
      return const [];
    }
    return List<T>.generate(length, (_) => read(), growable: false);
  }

  Map<String, String> stringMap() {
    final length = uint();
    if (length == 0) {
      return const {};
    }
    final map = <String, String>{};
    for (var i = 0; i < length; i++) {
      final key = string();
      map[key] = string();
    }
    return map;
  }

  AppstreamComponent component() {
    final id = string();
    final type = AppstreamComponentType.values[uint()];
    final package = optionalString();
    final name = stringMap();
    final summary = stringMap();
    final description = stringMap();
    final developerName = stringMap();
    final projectLicense = optionalString();
    final projectGroup = optionalString();
    final icons = list(icon);
    final urls = list(url);
    final categories = list(string);
    final keywords = <String, List<String>>{};
    for (var i = 0, length = uint(); i < length; i++) {
      final locale = string();
      keywords[locale] = list(string);
    }
    final screenshots = list(screenshot);
    final compulsoryForDesktops = list(string);
    final releases = list(release);
    final provides = list(this.provides);
    final launchables = list(launchable);
    final languages = list(language);
    final bundles = list(bundle);
    final custom = list(stringMap);
    final contentRatings = <String, Map<String, AppstreamContentRating>>{};
    for (var i = 0, length = uint(); i < length; i++) {
      final system = string();
      final ratings = <String, AppstreamContentRating>{};
      for (var j = 0, count = uint(); j < count; j++) {
        final category = string();
        ratings[category] = AppstreamContentRating.values[uint()];
      }
      contentRatings[system] = ratings;
    }
    return AppstreamComponent(
      id: id,
      type: type,
      package: package,
      name: name,
      summary: summary,
      description: description,
      developerName: developerName,
      projectLicense: projectLicense,
      projectGroup: projectGroup,
      icons: icons,
      urls: urls,
      categories: categories,
      keywords: keywords,
      screenshots: screenshots,
      compulsoryForDesktops: compulsoryForDesktops,
      releases: releases,
      provides: provides,
      launchables: launchables,
      languages: languages,
      bundles: bundles,
      custom: custom,
      contentRatings: contentRatings,
    );
  }

  AppstreamIcon icon() {
    switch (uint()) {
      case 0:
        return AppstreamStockIcon(string());
      case 1:
        final name = string();
        final width = optionalInteger();
        return AppstreamCachedIcon(
          name,
          width: width,
          height: optionalInteger(),
        );
      case 2:
        final filename = string();
        final width = optionalInteger();
        return AppstreamLocalIcon(
          filename,
          width: width,
          height: optionalInteger(),
        );
      case 3:
        final url = string();
        final width = optionalInteger();
        return AppstreamRemoteIcon(
          url,
          width: width,
          height: optionalInteger(),
        );
    }
    throw const FormatException('Unknown icon type');
  }

  AppstreamUrl url() {
    final url = string();
    return AppstreamUrl(url, type: AppstreamUrlType.values[uint()]);
  }

  AppstreamScreenshot screenshot() {
    final images = list(image);
    final caption = stringMap();
    return AppstreamScreenshot(
      images: images,
      caption: caption,
      isDefault: boolean(),
    );
  }

  AppstreamImage image() {
    final type = AppstreamImageType.values[uint()];
    final url = string();
    final width = optionalInteger();
    final height = optionalInteger();
    return AppstreamImage(
      type: type,
      url: url,
      width: width,
      height: height,
      lang: optionalString(),
    );
  }

  AppstreamRelease release() {
    final version = optionalString();
    final date = optionalDate();
    final type = AppstreamReleaseType.values[uint()];
    final urgency = AppstreamReleaseUrgency.values[uint()];
    final description = stringMap();
    final url = optionalString();
    return AppstreamRelease(
      version: version,
      date: date,
      type: type,
      urgency: urgency,
      description: description,
      url: url,
      issues: list(issue),
    );
  }

  AppstreamIssue issue() {
    final type = AppstreamIssueType.values[uint()];
    final id = string();
    return AppstreamIssue(id, type: type, url: optionalString());
  }

  AppstreamProvides provides() {
    switch (uint()) {
      case 0:
        return AppstreamProvidesMediatype(string());
      case 1:
        return AppstreamProvidesLibrary(string());
      case 2:
        return AppstreamProvidesBinary(string());
      case 3:
        return AppstreamProvidesFont(string());
      case 4:
        return AppstreamProvidesModalias(string());
      case 5:
        final type = AppstreamFirmwareType.values[uint()];
        return AppstreamProvidesFirmware(type, string());
      case 6:
        return AppstreamProvidesPython2(string());
      case 7:
        return AppstreamProvidesPython3(string());
      case 8:
        final type = AppstreamDBusType.values[uint()];
        return AppstreamProvidesDBus(type, string());
      case 9:
        return AppstreamProvidesId(string());
    }
    throw const FormatException('Unknown provides type');
  }

  AppstreamLaunchable launchable() {
    switch (uint()) {
      case 0:
        return AppstreamLaunchableDesktopId(string());
      case 1:
        return AppstreamLaunchableService(string());
      case 2:
        return AppstreamLaunchableCockpitManifest(string());
      case 3:
        return AppstreamLaunchableUrl(string());
    }
    throw const FormatException('Unknown launchable type');
  }

  AppstreamLanguage language() {
    final locale = string();
    return AppstreamLanguage(locale, percentage: optionalInteger());
  }

  AppstreamBundle bundle() {
    final id = string();
    return AppstreamBundle(id, type: AppstreamBundleType.values[uint()]);
  }
}
