import 'package:xml/xml.dart';
import 'package:yaml/yaml.dart';

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

enum AppstreamImageType { source, thumbnail }

class AppstreamImage {
  final AppstreamImageType type;
  final String url;
  final int? width;
  final int? height;
  final String? lang;

  const AppstreamImage(
      {required this.type,
      required this.url,
      this.width,
      this.height,
      this.lang});

  @override
  bool operator ==(other) =>
      other is AppstreamImage &&
      other.type == type &&
      other.url == url &&
      other.width == width &&
      other.height == height &&
      other.lang == lang;

  @override
  String toString() =>
      "$runtimeType(type: $type, url: '$url', width: $width, height: $height, lang: $lang)";
}

class AppstreamScreenshot {
  final List<AppstreamImage> images;
  final Map<String, String> caption;
  final bool isDefault;

  const AppstreamScreenshot(
      {this.images = const [],
      this.caption = const {},
      this.isDefault = false});

  @override
  bool operator ==(other) =>
      other is AppstreamScreenshot &&
      _listsEqual(other.images, images) &&
      _mapsEqual(other.caption, caption) &&
      other.isDefault == isDefault;

  @override
  String toString() =>
      '$runtimeType(images: $images, caption: $caption, isDefault: $isDefault)';
}

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

enum AppstreamComponentType {
  unknown,
  generic,
  desktopApplication,
  consoleApplication,
  webApplication,
  addon,
  font,
  codec,
  inputMethod,
  firmware,
  driver,
  localization,
  service,
  repository,
  operatingSystem,
  iconTheme,
  runtime
}

class AppstreamComponent {
  final String id;
  final AppstreamComponentType type;
  final String package;
  final Map<String, String> name;
  final Map<String, String> summary;
  final List<AppstreamIcon> icons;
  final List<AppstreamUrl> urls;
  final List<AppstreamScreenshot> screenshots;

  const AppstreamComponent(
      {required this.id,
      required this.type,
      required this.package,
      required this.name,
      required this.summary,
      this.icons = const [],
      this.urls = const [],
      this.screenshots = const []});

  @override
  String toString() =>
      '$runtimeType(id: $id, type: $type, package: $package, name: $name, summary: $summary, icons: $icons, urls: $urls, screenshots: $screenshots)';
}

class AppstreamCollection {
  final String version;
  final String origin;
  final String? architecture;
  final int? priority;
  final List<AppstreamComponent> components;

  AppstreamCollection(
      {this.version = '0.14',
      required this.origin,
      this.architecture,
      this.priority,
      Iterable<AppstreamComponent> components = const []})
      : components = List<AppstreamComponent>.from(components);

  factory AppstreamCollection.fromXml(String xml) {
    var document = XmlDocument.parse(xml);

    var root = document.getElement('components');
    if (root == null) {
      throw FormatException("XML document doesn't contain components tag");
    }

    var version = root.getElement('version');
    if (version == null) {
      throw FormatException('Missing AppStream version');
    }
    var origin = root.getElement('origin');
    if (origin == null) {
      throw FormatException('Missing repository origin');
    }

    var components = <AppstreamComponent>[];
    for (var component in root.children
        .whereType<XmlElement>()
        .where((e) => e.name.local == 'component')) {
      var typeName = component.getAttribute('type');
      if (typeName == null) {
        throw FormatException('Missing component type');
      }
      var type = {
            'generic': AppstreamComponentType.generic,
            'desktop-application': AppstreamComponentType.desktopApplication,
            'console-application': AppstreamComponentType.consoleApplication,
            'web-application': AppstreamComponentType.webApplication,
            'addon': AppstreamComponentType.addon,
            'font': AppstreamComponentType.font,
            'codec': AppstreamComponentType.codec,
            'inputMethod': AppstreamComponentType.inputMethod,
            'firmware': AppstreamComponentType.firmware,
            'driver': AppstreamComponentType.driver,
            'localization': AppstreamComponentType.localization,
            'service': AppstreamComponentType.service,
            'repository': AppstreamComponentType.repository,
            'operating-system': AppstreamComponentType.operatingSystem,
            'icon-theme': AppstreamComponentType.iconTheme,
            'runtime': AppstreamComponentType.runtime
          }[typeName] ??
          AppstreamComponentType.unknown;

      var id = component.getElement('id');
      if (id == null) {
        throw FormatException('Missing component ID');
      }
      var package = component.getElement('pkgname');
      if (package == null) {
        throw FormatException('Missing component package');
      }
      var name = _getXmlTranslatedString(component, 'name');
      var summary = _getXmlTranslatedString(component, 'summary');

      var elements = component.children.whereType<XmlElement>();

      var icons = <AppstreamIcon>[];
      for (var icon in elements.where((e) => e.name.local == 'icon')) {
        var type = icon.getAttribute('type');
        if (type == null) {
          throw FormatException('Missing icon type');
        }
        var w = icon.getAttribute('width');
        var width = w != null ? int.parse(w) : null;
        var h = icon.getAttribute('height');
        var height = h != null ? int.parse(h) : null;
        switch (type) {
          case 'stock':
            icons.add(AppstreamStockIcon(icon.text));
            break;
          case 'cached':
            icons.add(
                AppstreamCachedIcon(icon.text, width: width, height: height));
            break;
          case 'local':
            icons.add(
                AppstreamLocalIcon(icon.text, width: width, height: height));
            break;
          case 'remote':
            icons.add(
                AppstreamRemoteIcon(icon.text, width: width, height: height));
            break;
        }
      }

      var urls = <AppstreamUrl>[];
      for (var url in elements.where((e) => e.name.local == 'url')) {
        var type = {
          'homepage': AppstreamUrlType.homepage,
          'bugtracker': AppstreamUrlType.bugtracker,
          'faq': AppstreamUrlType.faq,
          'help': AppstreamUrlType.help,
          'donation': AppstreamUrlType.donation,
          'translate': AppstreamUrlType.translate,
          'contact': AppstreamUrlType.contact
        }[url.getAttribute('type')];
        if (type == null) {
          throw FormatException('Missing/unknown Url type');
        }
        urls.add(AppstreamUrl(url.text, type: type));
      }

      var screenshots = <AppstreamScreenshot>[];
      for (var screenshot
          in elements.where((e) => e.name.local == 'screenshot')) {
        var isDefault = screenshot.getAttribute('type') == 'default';
        var caption = _getXmlTranslatedString(screenshot, 'caption');
        var images = <AppstreamImage>[];
        for (var imageElement in screenshot.children
            .whereType<XmlElement>()
            .where((e) => e.name.local == 'image')) {
          var typeName = imageElement.getAttribute('type');
          if (typeName == null) {
            throw FormatException('Missing image type');
          }
          var type = {
            'source': AppstreamImageType.source,
            'thumbnail': AppstreamImageType.thumbnail
          }[typeName];
          if (type == null) {
            throw FormatException('Unknown image type');
          }
          var w = imageElement.getAttribute('width');
          var width = w != null ? int.parse(w) : null;
          var h = imageElement.getAttribute('height');
          var height = h != null ? int.parse(h) : null;
          var lang = imageElement.getAttribute('xml:lang');
          images.add(AppstreamImage(
              type: type,
              url: imageElement.text,
              width: width,
              height: height,
              lang: lang));
        }
        screenshots.add(AppstreamScreenshot(
            images: images, caption: caption, isDefault: isDefault));
      }

      components.add(AppstreamComponent(
          id: id.text,
          type: type,
          package: package.text,
          name: name,
          summary: summary,
          icons: icons,
          urls: urls,
          screenshots: screenshots));
    }

    return AppstreamCollection(
        version: version.text, origin: origin.text, components: components);
  }

  factory AppstreamCollection.fromYaml(String yaml) {
    var yamlDocuments = loadYamlDocuments(yaml);
    if (yamlDocuments.isEmpty) {
      throw FormatException('Empty YAML file');
    }
    var header = yamlDocuments[0];
    if (!(header.contents is YamlMap)) {
      throw FormatException('Invalid DEP-11 header');
    }
    var headerMap = (header.contents as YamlMap);
    var file = headerMap['File'];
    if (file != 'DEP-11') {
      throw FormatException('Not a DEP-11 file');
    }
    var version = headerMap['Version'];
    if (version == null) {
      throw FormatException('Missing AppStream version');
    }
    var origin = headerMap['Origin'];
    if (origin == null) {
      throw FormatException('Missing repository origin');
    }
    var priorityString = headerMap['Priority'];
    var priority = priorityString != null ? int.parse(priorityString) : null;
    var mediaBaseUrl = headerMap['MediaBaseUrl'];
    var architecture = headerMap['Architecture'];
    var components = <AppstreamComponent>[];
    for (var doc in yamlDocuments.skip(1)) {
      var component = doc.contents as YamlMap;
      var id = component['ID'];
      if (id == null) {
        throw FormatException('Missing component ID');
      }
      var typeName = component['Type'];
      if (typeName == null) {
        throw FormatException('Missing component type');
      }
      var type = {
            'generic': AppstreamComponentType.generic,
            'desktop-application': AppstreamComponentType.desktopApplication,
            'console-application': AppstreamComponentType.consoleApplication,
            'web-application': AppstreamComponentType.webApplication,
            'addon': AppstreamComponentType.addon,
            'font': AppstreamComponentType.font,
            'codec': AppstreamComponentType.codec,
            'inputMethod': AppstreamComponentType.inputMethod,
            'firmware': AppstreamComponentType.firmware,
            'driver': AppstreamComponentType.driver,
            'localization': AppstreamComponentType.localization,
            'service': AppstreamComponentType.service,
            'repository': AppstreamComponentType.repository,
            'operating-system': AppstreamComponentType.operatingSystem,
            'icon-theme': AppstreamComponentType.iconTheme,
            'runtime': AppstreamComponentType.runtime
          }[typeName] ??
          AppstreamComponentType.unknown;
      var package = component['Package'];
      if (package == null) {
        throw FormatException('Missing component package');
      }
      var name = component['Name'];
      if (name == null) {
        throw FormatException('Missing component name');
      }
      var summary = component['Summary'];
      if (summary == null) {
        throw FormatException('Missing component summary');
      }

      var icons = <AppstreamIcon>[];
      var icon = component['Icon'];
      if (icon != null) {
        for (var type in icon.keys) {
          switch (type) {
            case 'stock':
              icons.add(AppstreamStockIcon(icon[type]));
              break;
            case 'cached':
              for (var i in icon[type]) {
                icons.add(AppstreamCachedIcon(i['name'],
                    width: i['width'], height: i['height']));
              }
              break;
            case 'local':
              for (var i in icon[type]) {
                icons.add(AppstreamLocalIcon(i['name'],
                    width: i['width'], height: i['height']));
              }
              break;
            case 'remote':
              for (var i in icon[type]) {
                icons.add(AppstreamRemoteIcon(_makeUrl(mediaBaseUrl, i['url']),
                    width: i['width'], height: i['height']));
              }
              break;
          }
        }
      }

      var urls = <AppstreamUrl>[];
      var url = component['Url'];
      if (url != null) {
        for (var typeName in url.keys) {
          var type = {
            'homepage': AppstreamUrlType.homepage,
            'bugtracker': AppstreamUrlType.bugtracker,
            'faq': AppstreamUrlType.faq,
            'help': AppstreamUrlType.help,
            'donation': AppstreamUrlType.donation,
            'translate': AppstreamUrlType.translate,
            'contact': AppstreamUrlType.contact
          }[typeName];
          if (type == null) {
            throw FormatException('Missing/unknown Url type');
          }
          urls.add(AppstreamUrl(url[typeName], type: type));
        }
      }

      var screenshots = <AppstreamScreenshot>[];
      var screenshotsComponent = component['Screenshots'];
      if (screenshotsComponent != null) {
        if (!(screenshotsComponent is YamlList)) {
          throw FormatException('Invaid Screenshots type');
        }
        for (var screenshot in screenshotsComponent) {
          var isDefault = screenshot['default'] ?? 'false' == 'true';
          var caption = screenshot['caption'];
          var images = <AppstreamImage>[];
          var thumbnails = screenshot['thumbnails'];
          if (thumbnails != null) {
            if (!(thumbnails is YamlList)) {
              throw FormatException('Invaid thumbnails type');
            }
            for (var thumbnail in thumbnails) {
              var url = thumbnail['url'];
              if (url == null) {
                throw FormatException('Image missing Url');
              }
              var width = thumbnail['width'];
              var height = thumbnail['height'];
              var lang = thumbnail['lang'];
              images.add(AppstreamImage(
                  type: AppstreamImageType.thumbnail,
                  url: _makeUrl(mediaBaseUrl, url),
                  width: width,
                  height: height,
                  lang: lang));
            }
          }
          var sourceImage = screenshot['source-image'];
          if (sourceImage != null) {
            var url = sourceImage['url'];
            if (url == null) {
              throw FormatException('Image missing Url');
            }
            var width = sourceImage['width'];
            var height = sourceImage['height'];
            var lang = sourceImage['lang'];
            images.add(AppstreamImage(
                type: AppstreamImageType.source,
                url: _makeUrl(mediaBaseUrl, url),
                width: width,
                height: height,
                lang: lang));
          }
          screenshots.add(AppstreamScreenshot(
              images: images,
              caption: caption != null
                  ? _parseYamlTranslatedString(caption)
                  : const {},
              isDefault: isDefault));
        }
      }

      components.add(AppstreamComponent(
          id: id,
          type: type,
          package: package,
          name: _parseYamlTranslatedString(name),
          summary: _parseYamlTranslatedString(summary),
          icons: icons,
          urls: urls,
          screenshots: screenshots));
    }

    return AppstreamCollection(
        version: version,
        origin: origin,
        architecture: architecture,
        priority: priority,
        components: components);
  }

  @override
  String toString() => "$runtimeType(version: $version, origin: '$origin')";
}

Map<String, String> _parseYamlTranslatedString(dynamic value) {
  if (value is YamlMap) {
    return value.cast<String, String>();
  } else {
    throw FormatException('Invalid type for translated string');
  }
}

Map<String, String> _getXmlTranslatedString(XmlElement parent, String name) {
  var value = <String, String>{};
  for (var element in parent.children
      .whereType<XmlElement>()
      .where((e) => e.name.local == name)) {
    var lang = element.getAttribute('lang') ?? 'C';
    value[lang] = element.text;
  }

  return value;
}

String _makeUrl(String? mediaBaseUrl, String url) {
  if (mediaBaseUrl == null) {
    return url;
  }

  if (url.startsWith('http:') || url.startsWith('https:')) {
    return url;
  }

  return mediaBaseUrl + '/' + url;
}

bool _listsEqual<T>(List<T> a, List<T> b) {
  if (a.length != b.length) {
    return false;
  }

  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) {
      return false;
    }
  }

  return true;
}

bool _mapsEqual<K, V>(Map<K, V> a, Map<K, V> b) {
  if (a.length != b.length) {
    return false;
  }

  for (var key in a.keys) {
    if (a[key] != b[key]) {
      return false;
    }
  }

  return true;
}
