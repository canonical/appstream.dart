import 'package:xml/xml.dart';
import 'package:yaml/yaml.dart';

import 'bundle.dart';
import 'component.dart';
import 'icon.dart';
import 'language.dart';
import 'launchable.dart';
import 'provides.dart';
import 'release.dart';
import 'screenshot.dart';
import 'url.dart';

/// A collection of Appstream components.
class AppstreamCollection {
  /// The Appstream version these components comply with.
  final String version;

  /// The repository these components come from, e.g. 'ubuntu-hirsute-main'
  final String origin;

  /// The architecture these components are for, e.g. 'arm64'.
  final String? architecture;

  /// The priorization of this metadata file over other metadata.
  final int? priority;

  /// The components in this collection.
  final List<AppstreamComponent> components;

  /// Creates a new Appstream collection.
  AppstreamCollection(
      {this.version = '0.14',
      required this.origin,
      this.architecture,
      this.priority,
      Iterable<AppstreamComponent> components = const []})
      : components = List<AppstreamComponent>.from(components);

  /// Decodes an Appstream collection in XML format.
  factory AppstreamCollection.fromXml(String xml) {
    var document = XmlDocument.parse(xml);

    var root = document.getElement('components');
    if (root == null) {
      throw FormatException("XML document doesn't contain components tag");
    }

    var version = root.getAttribute('version');
    if (version == null) {
      throw FormatException('Missing AppStream version');
    }
    var origin = root.getAttribute('origin');
    if (origin == null) {
      throw FormatException('Missing repository origin');
    }
    var architecture = root.getAttribute('architecture');

    var components = <AppstreamComponent>[];
    for (var component in root.children
        .whereType<XmlElement>()
        .where((e) => e.name.local == 'component')) {
      var typeName = component.getAttribute('type');

      var type = typeName != null
          ? _parseComponentType(typeName)
          : AppstreamComponentType.unknown;

      var id = component.getElement('id');
      if (id == null) {
        throw FormatException('Missing component ID');
      }
      var pkg = component.getElement('pkgname');
      var package = pkg?.innerText;
      var name = _getXmlTranslatedString(component, 'name');
      var summary = _getXmlTranslatedString(component, 'summary');
      var description = _getXmlTranslatedString(component, 'description');
      var developerName = _getXmlTranslatedString(component, 'developer_name');
      var projectLicense = component.getElement('project_license')?.innerText;
      var projectGroup = component.getElement('project_group')?.innerText;

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
            icons.add(AppstreamStockIcon(icon.innerText));
            break;
          case 'cached':
            icons.add(AppstreamCachedIcon(icon.innerText,
                width: width, height: height));
            break;
          case 'local':
            icons.add(AppstreamLocalIcon(icon.innerText,
                width: width, height: height));
            break;
          case 'remote':
            icons.add(AppstreamRemoteIcon(icon.innerText,
                width: width, height: height));
            break;
        }
      }

      var urls = <AppstreamUrl>[];
      for (var url in elements.where((e) => e.name.local == 'url')) {
        var typeName = url.getAttribute('type');
        if (typeName == null) {
          throw FormatException('Missing Url type');
        }
        urls.add(AppstreamUrl(url.innerText, type: _parseUrlType(typeName)));
      }

      var launchables = <AppstreamLaunchable>[];
      for (var launchable
          in elements.where((e) => e.name.local == 'launchable')) {
        switch (launchable.getAttribute('type')) {
          case 'desktop-id':
            launchables.add(AppstreamLaunchableDesktopId(launchable.innerText));
            break;
          case 'service':
            launchables.add(AppstreamLaunchableService(launchable.innerText));
            break;
          case 'cockpit-manifest':
            launchables
                .add(AppstreamLaunchableCockpitManifest(launchable.innerText));
            break;
          case 'url':
            launchables.add(AppstreamLaunchableUrl(launchable.innerText));
            break;
        }
      }

      var categories = <String>[];
      var categoriesElement = component.getElement('categories');
      if (categoriesElement != null) {
        categories = categoriesElement.children
            .whereType<XmlElement>()
            .where((e) => e.name.local == 'category')
            .map((e) => e.innerText)
            .toList();
      }

      var keywords = <String, List<String>>{};
      for (var keywordsElement
          in elements.where((e) => e.name.local == 'keywords')) {
        var lang = keywordsElement.getAttribute('xml:lang') ?? 'C';
        keywords[lang] = keywordsElement.children
            .whereType<XmlElement>()
            .where((e) => e.name.local == 'keyword')
            .map((e) => e.innerText)
            .toList();
      }

      var screenshots = <AppstreamScreenshot>[];
      Iterable<XmlElement> screenshotElements;
      var screenshotsElement = component.getElement('screenshots');
      if (screenshotsElement != null) {
        screenshotElements = screenshotsElement.children
            .whereType<XmlElement>()
            .where((e) => e.name.local == 'screenshot');
      } else {
        screenshotElements =
            elements.where((e) => e.name.local == 'screenshot');
      }
      for (var screenshot in screenshotElements) {
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
              url: imageElement.innerText,
              width: width,
              height: height,
              lang: lang));
        }
        screenshots.add(AppstreamScreenshot(
            images: images, caption: caption, isDefault: isDefault));
      }

      var compulsoryForDesktops = elements
          .where((e) => e.name.local == 'compulsory_for_desktop')
          .map((e) => e.innerText)
          .toList();

      var releases = <AppstreamRelease>[];
      var releasesElement = component.getElement('releases');
      if (releasesElement != null) {
        for (var release in releasesElement.children
            .whereType<XmlElement>()
            .where((e) => e.name.local == 'release')) {
          var version = release.getAttribute('version');
          DateTime? date;
          var dateAttribute = release.getAttribute('date');
          var unixTimestamp = release.getAttribute('timestamp');
          if (unixTimestamp != null) {
            date = DateTime.fromMillisecondsSinceEpoch(
                int.parse(unixTimestamp) * 1000,
                isUtc: true);
          } else if (dateAttribute != null) {
            date = DateTime.parse(dateAttribute);
          }
          AppstreamReleaseType? type;
          var typeName = release.getAttribute('type');
          if (typeName != null) {
            type = _parseReleaseType(typeName);
          }
          AppstreamReleaseUrgency? urgency;
          var urgencyName = release.getAttribute('urgency');
          if (urgencyName != null) {
            urgency = _parseReleaseUrgency(urgencyName);
          }
          var description = _getXmlTranslatedString(release, 'description');
          var urlElement = release.getElement('url');
          var url = urlElement?.innerText;

          var issues = <AppstreamIssue>[];
          var issuesElement = release.getElement('issues');
          if (issuesElement != null) {
            for (var issue in issuesElement.children
                .whereType<XmlElement>()
                .where((e) => e.name.local == 'issue')) {
              AppstreamIssueType? type;
              var typeName = issue.getAttribute('type');
              if (typeName != null) {
                type = _parseIssueType(typeName);
              }
              var url = issue.getAttribute('url');
              issues.add(AppstreamIssue(issue.innerText,
                  type: type ?? AppstreamIssueType.generic, url: url));
            }
          }

          releases.add(AppstreamRelease(
              version: version,
              date: date,
              type: type ?? AppstreamReleaseType.stable,
              urgency: urgency ?? AppstreamReleaseUrgency.medium,
              description: description,
              url: url,
              issues: issues));
        }
      }

      var provides = <AppstreamProvides>[];
      var providesElement = component.getElement('provides');
      if (providesElement != null) {
        for (var element in providesElement.children.whereType<XmlElement>()) {
          switch (element.name.local) {
            case 'mediatype':
              provides.add(AppstreamProvidesMediatype(element.innerText));
              break;
            case 'library':
              provides.add(AppstreamProvidesLibrary(element.innerText));
              break;
            case 'binary':
              provides.add(AppstreamProvidesBinary(element.innerText));
              break;
            case 'font':
              provides.add(AppstreamProvidesFont(element.innerText));
              break;
            case 'modalias':
              provides.add(AppstreamProvidesModalias(element.innerText));
              break;
            case 'firmware':
              var typeName = element.getAttribute('type');
              if (typeName == null) {
                throw FormatException('Missing firmware type');
              }
              var type = {
                'runtime': AppstreamFirmwareType.runtime,
                'flashed': AppstreamFirmwareType.flashed
              }[typeName];
              if (type == null) {
                throw FormatException('Unknown firmware type $typeName');
              }
              provides.add(AppstreamProvidesFirmware(type, element.innerText));
              break;
            case 'python2':
              provides.add(AppstreamProvidesPython2(element.innerText));
              break;
            case 'python3':
              provides.add(AppstreamProvidesPython3(element.innerText));
              break;
            case 'dbus':
              var type = element.getAttribute('type');
              if (type == null) {
                throw FormatException('Missing DBus bus type');
              }
              provides.add(AppstreamProvidesDBus(
                  _parseDBusType(type), element.innerText));
              break;
            case 'id':
              provides.add(AppstreamProvidesId(element.innerText));
              break;
          }
        }
      }

      var languages = <AppstreamLanguage>[];
      var languagesElement = component.getElement('languages');
      if (languagesElement != null) {
        for (var language in languagesElement.children
            .whereType<XmlElement>()
            .where((e) => e.name.local == 'lang')) {
          var percentage = language.getAttribute('percentage');
          languages.add(AppstreamLanguage(language.innerText,
              percentage: percentage != null ? int.parse(percentage) : null));
        }
      }

      var contentRatings = <String, Map<String, AppstreamContentRating>>{};
      for (var contentRating
          in elements.where((e) => e.name.local == 'content_rating')) {
        var type = contentRating.getAttribute('type');
        if (type == null) {
          throw FormatException('Missing content rating type');
        }
        var ratings = <String, AppstreamContentRating>{};
        for (var contentAttribute in contentRating.children
            .whereType<XmlElement>()
            .where((e) => e.name.local == 'content_attribute')) {
          var id = contentAttribute.getAttribute('id');
          if (id == null) {
            throw FormatException('Missing content attribute id');
          }
          ratings[id] = _parseContentRating(contentAttribute.innerText);
        }
        contentRatings[type] = ratings;
      }

      var bundles = <AppstreamBundle>[];
      var bundleElement = component.getElement('bundle');
      if (bundleElement != null) {
        var typeName = bundleElement.getAttribute('type');

        var type = typeName != null
            ? _parseBundleType(typeName)
            : AppstreamBundleType.unknown;
        bundles.add(AppstreamBundle(bundleElement.innerText, type: type));
      }

      components.add(AppstreamComponent(
          id: id.innerText,
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
          launchables: launchables,
          categories: categories,
          keywords: keywords,
          screenshots: screenshots,
          compulsoryForDesktops: compulsoryForDesktops,
          releases: releases,
          provides: provides,
          languages: languages,
          bundles: bundles,
          contentRatings: contentRatings));
    }

    return AppstreamCollection(
        version: version,
        origin: origin,
        architecture: architecture,
        components: components);
  }

  // Very dumb removal of invalid YAML documents.
  // See https://github.com/canonical/appstream.dart/issues/15.
  // Fixing these documents would be much costlier and error-prone,
  // hence this simplistic approach to just filter out invalid documents.
  static String _removeInvalidDocuments(String yaml) {
    String processNode(String document) {
      try {
        loadYamlDocument(document);
        return document;
      } on YamlException {
        return '';
      }
    }

    final documentSeparator = '\n---\n';
    final documents = yaml.split(documentSeparator);
    for (var i = 0; i < documents.length; ++i) {
      documents[i] = processNode(documents[i]);
    }
    return documents.where((e) => e.isNotEmpty).join(documentSeparator);
  }

  /// Decodes an Appstream collection in YAML format.
  factory AppstreamCollection.fromYaml(String yaml) {
    var yamlDocuments = loadYamlDocuments(_removeInvalidDocuments(yaml));
    if (yamlDocuments.isEmpty) {
      throw FormatException('Empty YAML file');
    }
    var header = yamlDocuments[0];
    if (header.contents is! YamlMap) {
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
    var priority = headerMap['Priority'];
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

      var type = typeName != null
          ? _parseComponentType(typeName)
          : AppstreamComponentType.unknown;

      var package = component['Package'];
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
          urls.add(
              AppstreamUrl(url[typeName] ?? '', type: _parseUrlType(typeName)));
        }
      }

      var launchables = <AppstreamLaunchable>[];
      var launchable = component['Launchable'];
      if (launchable != null) {
        if (launchable is! YamlMap) {
          throw FormatException('Invalid Launchable type');
        }
        for (var typeName in launchable.keys) {
          var launchableList = launchable[typeName];
          if (launchableList is! YamlList) {
            throw FormatException('Invalid Launchable type');
          }
          switch (typeName) {
            case 'desktop-id':
              launchables.addAll(
                  launchableList.map((l) => AppstreamLaunchableDesktopId(l)));
              break;
            case 'service':
              launchables.addAll(
                  launchableList.map((l) => AppstreamLaunchableService(l)));
              break;
            case 'cockpit-manifest':
              launchables.addAll(launchableList
                  .map((l) => AppstreamLaunchableCockpitManifest(l)));
              break;
            case 'url':
              launchables
                  .addAll(launchableList.map((l) => AppstreamLaunchableUrl(l)));
              break;
          }
        }
      }

      var categories = <String>[];
      var categoriesComponent = component['Categories'];
      if (categoriesComponent != null) {
        if (categoriesComponent is! YamlList) {
          throw FormatException('Invalid Categories type');
        }
        categories.addAll(categoriesComponent.cast<String>());
      }

      var keywords = <String, List<String>>{};
      var keywordsComponent = component['Keywords'];
      if (keywordsComponent != null) {
        if (keywordsComponent is! YamlMap) {
          throw FormatException('Invalid Keywords type');
        }
        keywords = keywordsComponent.map(
          (lang, keywordList) => MapEntry(
            lang,
            keywordList.nodes
                .where((e) => e.value != null)
                .map<String>((e) => e.value.toString())
                .toList(),
          ),
        );
      }

      var screenshots = <AppstreamScreenshot>[];
      var screenshotsComponent = component['Screenshots'];
      if (screenshotsComponent != null) {
        if (screenshotsComponent is! YamlList) {
          throw FormatException('Invalid Screenshots type');
        }
        for (var screenshot in screenshotsComponent) {
          var isDefault = screenshot['default'] ?? 'false' == 'true';
          var caption = screenshot['caption'];
          var images = <AppstreamImage>[];
          var thumbnails = screenshot['thumbnails'];
          if (thumbnails != null) {
            if (thumbnails is! YamlList) {
              throw FormatException('Invalid thumbnails type');
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

      var compulsoryForDesktops = <String>[];
      var compulsoryForDesktopsComponent = component['CompulsoryForDesktops'];
      if (compulsoryForDesktopsComponent != null) {
        if (compulsoryForDesktopsComponent is! YamlList) {
          throw FormatException('Invalid CompulsoryForDesktops type');
        }
        compulsoryForDesktops
            .addAll(compulsoryForDesktopsComponent.cast<String>());
      }

      var releases = <AppstreamRelease>[];
      var releasesComponent = component['Releases'];
      if (releasesComponent != null) {
        if (releasesComponent is! YamlList) {
          throw FormatException('Invalid Releases type');
        }
        for (var release in releasesComponent) {
          if (release is! YamlMap) {
            throw FormatException('Invalid release type');
          }
          var version = release['version'];
          DateTime? date;
          var dateAttribute = release['date'];
          var unixTimestamp = release['unix-timestamp'];
          if (unixTimestamp != null) {
            date = DateTime.fromMillisecondsSinceEpoch(unixTimestamp * 1000,
                isUtc: true);
          } else if (dateAttribute != null) {
            date = DateTime.parse(dateAttribute);
          }
          AppstreamReleaseType? type;
          var typeName = release['type'];
          if (typeName != null) {
            type = _parseReleaseType(typeName);
          }
          AppstreamReleaseUrgency? urgency;
          var urgencyName = release['urgency'];
          if (urgencyName != null) {
            urgency = _parseReleaseUrgency(urgencyName);
          }
          var description = release['description'];
          var url = release['url']?['details'];
          var issues = <AppstreamIssue>[];
          var issuesComponent = release['issues'];
          if (issuesComponent != null) {
            if (issuesComponent is! YamlList) {
              throw FormatException('Invalid issues type');
            }
            for (var issue in issuesComponent) {
              if (issue is! YamlMap) {
                throw FormatException('Invalid issue type');
              }
              var id = issue['id'];
              if (id == null) {
                throw FormatException('Issue missing id');
              }
              AppstreamIssueType? type;
              var typeName = issue['type'];
              if (typeName != null) {
                type = _parseIssueType(typeName);
              }
              var url = issue['url'];
              issues.add(AppstreamIssue(id,
                  type: type ?? AppstreamIssueType.generic, url: url));
            }
          }
          releases.add(AppstreamRelease(
              version: _parseYamlVersion(version),
              date: date,
              type: type ?? AppstreamReleaseType.stable,
              urgency: urgency ?? AppstreamReleaseUrgency.medium,
              description: description != null
                  ? _parseYamlTranslatedString(description)
                  : const {},
              url: url,
              issues: issues));
        }
      }

      var provides = <AppstreamProvides>[];
      var providesComponent = component['Provides'];
      if (providesComponent != null) {
        if (providesComponent is! YamlMap) {
          throw FormatException('Invalid Provides type');
        }
        for (var type in providesComponent.keys) {
          var values = providesComponent[type];
          if (values is! YamlList) {
            throw FormatException('Invalid $type provides');
          }
          switch (type) {
            case 'mediatypes':
            case 'mimetypes':
              provides.addAll(values.map((e) => AppstreamProvidesMediatype(e)));
              break;
            case 'libraries':
              provides.addAll(values.map((e) => AppstreamProvidesLibrary(e)));
              break;
            case 'binaries':
              provides.addAll(values.map((e) => AppstreamProvidesBinary(e)));
              break;
            case 'fonts':
              for (var fontComponent in values) {
                if (fontComponent is! YamlMap) {
                  throw FormatException('Invalid font provides');
                }
                var name = fontComponent['name'];
                if (name == null) {
                  throw FormatException('Missing font name');
                }
                provides.add(AppstreamProvidesFont(name));
              }
              break;
            case 'firmware':
              for (var firmwareComponent in values) {
                if (firmwareComponent is! YamlMap) {
                  throw FormatException('Invalid firmware provides');
                }
                var type = firmwareComponent['type'];
                switch (type) {
                  case 'runtime':
                    var file = firmwareComponent['file'];
                    if (file == null) {
                      throw FormatException('Missing firmware file');
                    }
                    provides.add(AppstreamProvidesFirmware(
                        AppstreamFirmwareType.runtime, file));
                    break;
                  case 'flashed':
                    var guid = firmwareComponent['guid'];
                    if (guid == null) {
                      throw FormatException('Missing firmware guid');
                    }
                    provides.add(AppstreamProvidesFirmware(
                        AppstreamFirmwareType.flashed, guid));
                    break;
                }
              }
              break;
            case 'python2':
              for (var moduleName in values) {
                provides.add(AppstreamProvidesPython2(moduleName));
              }
              break;
            case 'python3':
              for (var moduleName in values) {
                provides.add(AppstreamProvidesPython3(moduleName));
              }
              break;
            case 'modaliases':
              for (var modalias in values) {
                provides.add(AppstreamProvidesModalias(modalias));
              }
              break;
            case 'dbus':
              for (var dbusComponent in values) {
                if (dbusComponent is! YamlMap) {
                  throw FormatException('Invalid dbus provides');
                }
                var type = dbusComponent['type'];
                if (type == null) {
                  throw FormatException('Missing DBus bus type');
                }
                var service = dbusComponent['service'];
                if (service == null) {
                  throw FormatException('Missing DBus service name');
                }
                provides
                    .add(AppstreamProvidesDBus(_parseDBusType(type), service));
              }
              break;
            case 'ids':
              provides.addAll(values.map((e) => AppstreamProvidesId(e)));
              break;
          }
        }
      }

      var languages = <AppstreamLanguage>[];
      var languagesComponent = component['Languages'];
      if (languagesComponent != null) {
        if (languagesComponent is! YamlList) {
          throw FormatException('Invalid Languages type');
        }

        for (var language in languagesComponent) {
          if (language is! YamlMap) {
            throw FormatException('Invalid language type');
          }
          var locale = language['locale'];
          if (locale == null) {
            throw FormatException('Missing language locale');
          }
          var percentage = language['percentage'];
          languages.add(AppstreamLanguage(locale, percentage: percentage));
        }
      }

      var contentRatings = <String, Map<String, AppstreamContentRating>>{};
      var contentRatingComponent = component['ContentRating'];
      if (contentRatingComponent != null) {
        if (contentRatingComponent is! YamlMap) {
          throw FormatException('Invalid ContentRating type');
        }
        for (var type in contentRatingComponent.keys) {
          contentRatings[type] = contentRatingComponent[type]
              .map<String, AppstreamContentRating>((key, value) =>
                  MapEntry(key as String, _parseContentRating(value)));
        }
      }

      var bundles = <AppstreamBundle>[];
      var bundlesComponent = component['Bundles'];
      if (bundlesComponent != null) {
        if (bundlesComponent is! YamlList) {
          throw FormatException('Invalid Bundle type');
        }
        for (var bundle in bundlesComponent) {
          if (bundle is! YamlMap) {
            throw FormatException('Invalid bundle type');
          }
          var typeName = bundle['type'];
          if (typeName == null) {
            throw FormatException('Missing bundle type');
          }
          var type = typeName != null
              ? _parseBundleType(typeName)
              : AppstreamBundleType.unknown;
          bundles.add(AppstreamBundle(bundle['id'], type: type));
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
          developerName: developerName != null
              ? _parseYamlTranslatedString(developerName)
              : const {},
          projectLicense: projectLicense,
          projectGroup: projectGroup,
          icons: icons,
          urls: urls,
          launchables: launchables,
          categories: categories,
          keywords: keywords,
          screenshots: screenshots,
          compulsoryForDesktops: compulsoryForDesktops,
          releases: releases,
          provides: provides,
          languages: languages,
          bundles: bundles,
          contentRatings: contentRatings));
    }

    return AppstreamCollection(
        version: _parseYamlVersion(version)!,
        origin: origin,
        architecture: architecture,
        priority: priority,
        components: components);
  }

  @override
  String toString() => "$runtimeType(version: $version, origin: '$origin')";
}

String? _parseYamlVersion(dynamic value) {
  if (value is double) {
    return value.toString();
  } else {
    return value as String?;
  }
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
    var lang =
        element.getAttribute('lang') ?? element.getAttribute('xml:lang') ?? 'C';
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

  return '$mediaBaseUrl/$url';
}

AppstreamComponentType _parseComponentType(String typeName) {
  return {
        'generic': AppstreamComponentType.generic,
        'desktop-application': AppstreamComponentType.desktopApplication,
        'console-application': AppstreamComponentType.consoleApplication,
        'web-application': AppstreamComponentType.webApplication,
        'addon': AppstreamComponentType.addon,
        'font': AppstreamComponentType.font,
        'codec': AppstreamComponentType.codec,
        'inputmethod': AppstreamComponentType.inputMethod,
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
}

AppstreamUrlType _parseUrlType(String typeName) {
  var type = {
    'homepage': AppstreamUrlType.homepage,
    'bugtracker': AppstreamUrlType.bugtracker,
    'faq': AppstreamUrlType.faq,
    'help': AppstreamUrlType.help,
    'donation': AppstreamUrlType.donation,
    'translate': AppstreamUrlType.translate,
    'contact': AppstreamUrlType.contact,
    'vcs-browser': AppstreamUrlType.vcsBrowser,
    'contribute': AppstreamUrlType.contribute
  }[typeName];
  if (type == null) {
    throw FormatException("Unknown url type '$typeName'");
  }
  return type;
}

AppstreamReleaseType _parseReleaseType(String typeName) {
  var type = {
    'stable': AppstreamReleaseType.stable,
    'development': AppstreamReleaseType.development
  }[typeName];
  if (type == null) {
    throw FormatException("Unknown release type '$typeName'");
  }
  return type;
}

AppstreamReleaseUrgency _parseReleaseUrgency(String urgencyName) {
  var urgency = {
    'low': AppstreamReleaseUrgency.low,
    'medium': AppstreamReleaseUrgency.medium,
    'high': AppstreamReleaseUrgency.high,
    'critical': AppstreamReleaseUrgency.critical
  }[urgencyName];
  if (urgency == null) {
    throw FormatException("Unknown release urgency '$urgencyName'");
  }
  return urgency;
}

AppstreamIssueType _parseIssueType(String typeName) {
  var type = {
    'generic': AppstreamIssueType.generic,
    'cve': AppstreamIssueType.cve
  }[typeName];
  if (type == null) {
    throw FormatException("Unknown issue type '$typeName'");
  }
  return type;
}

AppstreamDBusType _parseDBusType(String typeName) {
  var type = {
    'user': AppstreamDBusType.user,
    'session': AppstreamDBusType.session,
    'system': AppstreamDBusType.system
  }[typeName];
  if (type == null) {
    throw FormatException("Unknown DBus type '$typeName'");
  }
  return type;
}

AppstreamBundleType _parseBundleType(String typeName) {
  var type = {
    'package': AppstreamBundleType.package,
    'limba': AppstreamBundleType.limba,
    'flatpak': AppstreamBundleType.flatpak,
    'appimage': AppstreamBundleType.appimage,
    'snap': AppstreamBundleType.snap,
    'tarball': AppstreamBundleType.tarball,
    'cabinet': AppstreamBundleType.cabinet,
    'linglong': AppstreamBundleType.linglong,
    'sysupdate': AppstreamBundleType.sysupdate,
  }[typeName];
  if (type == null) {
    throw FormatException("Unknown bundle type '$typeName'");
  }
  return type;
}

AppstreamContentRating _parseContentRating(String ratingName) {
  var rating = {
    'none': AppstreamContentRating.none,
    'mild': AppstreamContentRating.mild,
    'moderate': AppstreamContentRating.moderate,
    'intense': AppstreamContentRating.intense
  }[ratingName];
  if (rating == null) {
    throw FormatException("Unknown content rating '$ratingName'");
  }
  return rating;
}
