import 'package:xml/xml.dart';
import 'package:yaml/yaml.dart';

import 'component.dart';
import 'icon.dart';
import 'screenshot.dart';
import 'url.dart';

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
      var description = _getXmlTranslatedString(component, 'description');
      var developerName = component.getElement('developer_name')?.text;
      var projectLicense = component.getElement('project_license')?.text;
      var projectGroup = component.getElement('project_group')?.text;

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

      var categories = <String>[];
      var categoriesElement = component.getElement('categories');
      if (categoriesElement != null) {
        categories = categoriesElement.children
            .whereType<XmlElement>()
            .where((e) => e.name.local == 'category')
            .map((e) => e.text)
            .toList();
      }

      var keywords = <String, List<String>>{};
      for (var keywordsElement
          in elements.where((e) => e.name.local == 'keywords')) {
        var lang = keywordsElement.getAttribute('xml:lang') ?? 'C';
        keywords[lang] = keywordsElement.children
            .whereType<XmlElement>()
            .where((e) => e.name.local == 'keyword')
            .map((e) => e.text)
            .toList();
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
          description: description,
          developerName: developerName,
          projectLicense: projectLicense,
          projectGroup: projectGroup,
          icons: icons,
          urls: urls,
          categories: categories,
          keywords: keywords,
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
      var description = component['Description'];
      var developerName = component['DeveloperName'];
      var projectLicense = component['ProjectLicense'];
      var projectGroup = component['ProjectGroup'];

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

      var categories = <String>[];
      var categoriesComponent = component['Categories'];
      if (categoriesComponent != null) {
        if (!(categoriesComponent is YamlList)) {
          throw FormatException('Invaid Categories type');
        }
        categories.addAll(categoriesComponent.cast<String>());
      }

      var keywords = <String, List<String>>{};
      var keywordsComponent = component['Keywords'];
      if (keywordsComponent != null) {
        if (!(keywordsComponent is YamlMap)) {
          throw FormatException('Invaid Keywords type');
        }
        keywords = keywordsComponent.map(
            (lang, keywordList) => MapEntry(lang, keywordList.cast<String>()));
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
          description: description != null
              ? _parseYamlTranslatedString(description)
              : const {},
          developerName: developerName,
          projectLicense: projectLicense,
          projectGroup: projectGroup,
          icons: icons,
          urls: urls,
          categories: categories,
          keywords: keywords,
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
    value[lang] = element.innerXml;
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
