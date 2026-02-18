import 'package:appstream/src/bundle.dart';
import 'package:appstream/src/component.dart';
import 'package:appstream/src/icon.dart';
import 'package:appstream/src/language.dart';
import 'package:appstream/src/launchable.dart';
import 'package:appstream/src/provides.dart';
import 'package:appstream/src/release.dart';
import 'package:appstream/src/screenshot.dart';
import 'package:appstream/src/url.dart';
import 'package:xml/xml.dart';
import 'package:yaml/yaml.dart';

/// A collection of Appstream components.
class AppstreamCollection {
  /// Creates a new Appstream collection.
  AppstreamCollection({
    required this.origin,
    this.version = '0.14',
    this.architecture,
    this.priority,
    Iterable<AppstreamComponent> components = const [],
  }) : components = List<AppstreamComponent>.from(components);

  /// Decodes an Appstream collection in XML format.
  factory AppstreamCollection.fromXml(String xml) {
    final document = XmlDocument.parse(xml);

    final root = document.getElement('components');
    if (root == null) {
      throw FormatException("XML document doesn't contain components tag");
    }

    final version = root.getAttribute('version');
    if (version == null) {
      throw FormatException('Missing AppStream version');
    }
    final origin = root.getAttribute('origin');
    if (origin == null) {
      throw FormatException('Missing repository origin');
    }
    final architecture = root.getAttribute('architecture');

    final components = <AppstreamComponent>[];
    for (final component in root.children
        .whereType<XmlElement>()
        .where((e) => e.name.local == 'component')) {
      final typeName = component.getAttribute('type');

      final type = typeName != null
          ? _parseComponentType(typeName)
          : AppstreamComponentType.unknown;

      final id = component.getElement('id');
      if (id == null) {
        throw FormatException('Missing component ID');
      }
      final pkg = component.getElement('pkgname');
      final package = pkg?.innerText;
      final name = _getXmlTranslatedString(component, 'name');
      final summary = _getXmlTranslatedString(component, 'summary');
      final description = _getXmlTranslatedString(component, 'description');
      final developerName =
          _getXmlTranslatedString(component, 'developer_name');
      final projectLicense = component.getElement('project_license')?.innerText;
      final projectGroup = component.getElement('project_group')?.innerText;

      final elements = component.children.whereType<XmlElement>();

      final icons = <AppstreamIcon>[];
      for (final icon in elements.where((e) => e.name.local == 'icon')) {
        final type = icon.getAttribute('type');
        if (type == null) {
          throw FormatException('Missing icon type');
        }
        final w = icon.getAttribute('width');
        final width = w != null ? int.parse(w) : null;
        final h = icon.getAttribute('height');
        final height = h != null ? int.parse(h) : null;
        switch (type) {
          case 'stock':
            icons.add(AppstreamStockIcon(icon.innerText));
            break;
          case 'cached':
            icons.add(
              AppstreamCachedIcon(
                icon.innerText,
                width: width,
                height: height,
              ),
            );
            break;
          case 'local':
            icons.add(
              AppstreamLocalIcon(
                icon.innerText,
                width: width,
                height: height,
              ),
            );
            break;
          case 'remote':
            icons.add(
              AppstreamRemoteIcon(
                icon.innerText,
                width: width,
                height: height,
              ),
            );
            break;
        }
      }

      final urls = <AppstreamUrl>[];
      for (final url in elements.where((e) => e.name.local == 'url')) {
        final typeName = url.getAttribute('type');
        if (typeName == null) {
          throw FormatException('Missing Url type');
        }
        urls.add(AppstreamUrl(url.innerText, type: _parseUrlType(typeName)));
      }

      final launchables = <AppstreamLaunchable>[];
      for (final launchable
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
      final categoriesElement = component.getElement('categories');
      if (categoriesElement != null) {
        categories = categoriesElement.children
            .whereType<XmlElement>()
            .where((e) => e.name.local == 'category')
            .map((e) => e.innerText)
            .toList();
      }

      final keywords = <String, List<String>>{};
      for (final keywordsElement
          in elements.where((e) => e.name.local == 'keywords')) {
        final lang = keywordsElement.getAttribute('xml:lang') ?? 'C';
        keywords[lang] = keywordsElement.children
            .whereType<XmlElement>()
            .where((e) => e.name.local == 'keyword')
            .map((e) => e.innerText)
            .toList();
      }

      final screenshots = <AppstreamScreenshot>[];
      Iterable<XmlElement> screenshotElements;
      final screenshotsElement = component.getElement('screenshots');
      if (screenshotsElement != null) {
        screenshotElements = screenshotsElement.children
            .whereType<XmlElement>()
            .where((e) => e.name.local == 'screenshot');
      } else {
        screenshotElements =
            elements.where((e) => e.name.local == 'screenshot');
      }
      for (final screenshot in screenshotElements) {
        final isDefault = screenshot.getAttribute('type') == 'default';
        final caption = _getXmlTranslatedString(screenshot, 'caption');
        final images = <AppstreamImage>[];
        for (final imageElement in screenshot.children
            .whereType<XmlElement>()
            .where((e) => e.name.local == 'image')) {
          final typeName = imageElement.getAttribute('type');
          if (typeName == null) {
            throw FormatException('Missing image type');
          }
          final type = {
            'source': AppstreamImageType.source,
            'thumbnail': AppstreamImageType.thumbnail,
          }[typeName];
          if (type == null) {
            throw FormatException('Unknown image type');
          }
          final w = imageElement.getAttribute('width');
          final width = w != null ? int.parse(w) : null;
          final h = imageElement.getAttribute('height');
          final height = h != null ? int.parse(h) : null;
          final lang = imageElement.getAttribute('xml:lang');
          images.add(
            AppstreamImage(
              type: type,
              url: imageElement.innerText,
              width: width,
              height: height,
              lang: lang,
            ),
          );
        }
        screenshots.add(
          AppstreamScreenshot(
            images: images,
            caption: caption,
            isDefault: isDefault,
          ),
        );
      }

      final compulsoryForDesktops = elements
          .where((e) => e.name.local == 'compulsory_for_desktop')
          .map((e) => e.innerText)
          .toList();

      final releases = <AppstreamRelease>[];
      final releasesElement = component.getElement('releases');
      if (releasesElement != null) {
        for (final release in releasesElement.children
            .whereType<XmlElement>()
            .where((e) => e.name.local == 'release')) {
          final version = release.getAttribute('version');
          DateTime? date;
          final dateAttribute = release.getAttribute('date');
          final unixTimestamp = release.getAttribute('timestamp');
          if (unixTimestamp != null) {
            date = DateTime.fromMillisecondsSinceEpoch(
              int.parse(unixTimestamp) * 1000,
              isUtc: true,
            );
          } else if (dateAttribute != null) {
            date = DateTime.parse(dateAttribute);
          }
          AppstreamReleaseType? type;
          final typeName = release.getAttribute('type');
          if (typeName != null) {
            type = _parseReleaseType(typeName);
          }
          AppstreamReleaseUrgency? urgency;
          final urgencyName = release.getAttribute('urgency');
          if (urgencyName != null) {
            urgency = _parseReleaseUrgency(urgencyName);
          }
          final description = _getXmlTranslatedString(release, 'description');
          final urlElement = release.getElement('url');
          final url = urlElement?.innerText;

          final issues = <AppstreamIssue>[];
          final issuesElement = release.getElement('issues');
          if (issuesElement != null) {
            for (final issue in issuesElement.children
                .whereType<XmlElement>()
                .where((e) => e.name.local == 'issue')) {
              AppstreamIssueType? type;
              final typeName = issue.getAttribute('type');
              if (typeName != null) {
                type = _parseIssueType(typeName);
              }
              final url = issue.getAttribute('url');
              issues.add(
                AppstreamIssue(
                  issue.innerText,
                  type: type ?? AppstreamIssueType.generic,
                  url: url,
                ),
              );
            }
          }

          releases.add(
            AppstreamRelease(
              version: version,
              date: date,
              type: type ?? AppstreamReleaseType.stable,
              urgency: urgency ?? AppstreamReleaseUrgency.medium,
              description: description,
              url: url,
              issues: issues,
            ),
          );
        }
      }

      final provides = <AppstreamProvides>[];
      final providesElement = component.getElement('provides');
      if (providesElement != null) {
        for (final element
            in providesElement.children.whereType<XmlElement>()) {
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
              final typeName = element.getAttribute('type');
              if (typeName == null) {
                throw FormatException('Missing firmware type');
              }
              final type = {
                'runtime': AppstreamFirmwareType.runtime,
                'flashed': AppstreamFirmwareType.flashed,
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
              final type = element.getAttribute('type');
              if (type == null) {
                throw FormatException('Missing DBus bus type');
              }
              provides.add(
                AppstreamProvidesDBus(
                  _parseDBusType(type),
                  element.innerText,
                ),
              );
              break;
            case 'id':
              provides.add(AppstreamProvidesId(element.innerText));
              break;
          }
        }
      }

      final languages = <AppstreamLanguage>[];
      final languagesElement = component.getElement('languages');
      if (languagesElement != null) {
        for (final language in languagesElement.children
            .whereType<XmlElement>()
            .where((e) => e.name.local == 'lang')) {
          final percentage = language.getAttribute('percentage');
          languages.add(
            AppstreamLanguage(
              language.innerText,
              percentage: percentage != null ? int.parse(percentage) : null,
            ),
          );
        }
      }

      final contentRatings = <String, Map<String, AppstreamContentRating>>{};
      for (final contentRating
          in elements.where((e) => e.name.local == 'content_rating')) {
        final type = contentRating.getAttribute('type');
        if (type == null) {
          throw FormatException('Missing content rating type');
        }
        final ratings = <String, AppstreamContentRating>{};
        for (final contentAttribute in contentRating.children
            .whereType<XmlElement>()
            .where((e) => e.name.local == 'content_attribute')) {
          final id = contentAttribute.getAttribute('id');
          if (id == null) {
            throw FormatException('Missing content attribute id');
          }
          ratings[id] = _parseContentRating(contentAttribute.innerText);
        }
        contentRatings[type] = ratings;
      }

      final bundles = <AppstreamBundle>[];
      final bundleElement = component.getElement('bundle');
      if (bundleElement != null) {
        final typeName = bundleElement.getAttribute('type');

        final type = typeName != null
            ? _parseBundleType(typeName)
            : AppstreamBundleType.unknown;
        bundles.add(AppstreamBundle(bundleElement.innerText, type: type));
      }

      final custom = <Map<String, String>>[];
      final customElement = component.getElement('custom');
      if (customElement != null) {
        for (final item in customElement.children) {
          final key = item.getAttribute('key');
          if (key != null) {
            custom.add({key: item.innerText});
          }
        }
      }

      components.add(
        AppstreamComponent(
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
          custom: custom,
          contentRatings: contentRatings,
        ),
      );
    }

    return AppstreamCollection(
      version: version,
      origin: origin,
      architecture: architecture,
      components: components,
    );
  }

  /// Decodes an Appstream collection in YAML format.
  factory AppstreamCollection.fromYaml(String yaml) {
    final yamlDocuments = loadYamlDocuments(_removeInvalidDocuments(yaml));
    if (yamlDocuments.isEmpty) {
      throw FormatException('Empty YAML file');
    }
    final header = yamlDocuments[0];
    if (header.contents is! YamlMap) {
      throw FormatException('Invalid DEP-11 header');
    }
    final headerMap = header.contents as YamlMap;
    final file = headerMap['File'];
    if (file != 'DEP-11') {
      throw FormatException('Not a DEP-11 file');
    }
    final version = headerMap['Version'];
    if (version == null) {
      throw FormatException('Missing AppStream version');
    }
    final origin = headerMap['Origin'] as String?;
    if (origin == null) {
      throw FormatException('Missing repository origin');
    }
    final priority = headerMap['Priority'] as int?;
    final mediaBaseUrl = headerMap['MediaBaseUrl'] as String?;
    final architecture = headerMap['Architecture'] as String?;
    final components = <AppstreamComponent>[];
    for (final doc in yamlDocuments.skip(1)) {
      final component = doc.contents as YamlMap;
      final id = component['ID'] as String?;
      if (id == null) {
        throw FormatException('Missing component ID');
      }
      final typeName = component['Type'] as String?;

      final type = typeName != null
          ? _parseComponentType(typeName)
          : AppstreamComponentType.unknown;

      final package = component['Package'] as String?;
      final name = component['Name'] as YamlNode?;
      if (name == null) {
        throw FormatException('Missing component name');
      }
      final summary = component['Summary'];
      if (summary == null) {
        throw FormatException('Missing component summary');
      }
      final description = component['Description'];
      final developerName = component['DeveloperName'];
      final projectLicense = component['ProjectLicense'] as String?;
      final projectGroup = component['ProjectGroup'] as String?;

      final icons = <AppstreamIcon>[];
      final icon = component['Icon'] as YamlMap?;
      if (icon != null) {
        for (final type in icon.keys) {
          switch (type) {
            case 'stock':
              icons.add(AppstreamStockIcon(icon[type] as String));
              break;
            case 'cached':
              for (final i in icon[type] as YamlList) {
                icons.add(
                  AppstreamCachedIcon(
                    i['name'] as String,
                    width: i['width'] as int?,
                    height: i['height'] as int?,
                  ),
                );
              }
              break;
            case 'local':
              for (final i in icon[type] as YamlList) {
                icons.add(
                  AppstreamLocalIcon(
                    i['name'] as String,
                    width: i['width'] as int?,
                    height: i['height'] as int?,
                  ),
                );
              }
              break;
            case 'remote':
              for (final i in icon[type] as YamlList) {
                icons.add(
                  AppstreamRemoteIcon(
                    _makeUrl(mediaBaseUrl, i['url'] as String),
                    width: i['width'] as int?,
                    height: i['height'] as int?,
                  ),
                );
              }
              break;
          }
        }
      }

      final urls = <AppstreamUrl>[];
      final url = component['Url'] as YamlMap?;
      if (url != null) {
        for (final typeName in url.keys) {
          urls.add(
            AppstreamUrl(
              url[typeName] as String? ?? '',
              type: _parseUrlType(typeName as String),
            ),
          );
        }
      }

      final launchables = <AppstreamLaunchable>[];
      final launchable = component['Launchable'] as YamlMap?;
      if (launchable != null) {
        for (final typeName in launchable.keys) {
          final launchableList = launchable[typeName] as YamlList?;
          if (launchableList is! YamlList) {
            throw FormatException('Invalid Launchable type');
          }
          switch (typeName) {
            case 'desktop-id':
              launchables.addAll(
                launchableList
                    .map((l) => AppstreamLaunchableDesktopId(l as String)),
              );
              break;
            case 'service':
              launchables.addAll(
                launchableList
                    .map((l) => AppstreamLaunchableService(l as String)),
              );
              break;
            case 'cockpit-manifest':
              launchables.addAll(
                launchableList.map(
                  (l) => AppstreamLaunchableCockpitManifest(l as String),
                ),
              );
              break;
            case 'url':
              launchables.addAll(
                launchableList.map((l) => AppstreamLaunchableUrl(l as String)),
              );
              break;
          }
        }
      }

      final categories = <String>[];
      final categoriesComponent = component['Categories'] as YamlList?;
      if (categoriesComponent != null) {
        categories.addAll(categoriesComponent.cast<String>());
      }

      var keywords = <String, List<String>>{};
      final keywordsComponent = component['Keywords'] as YamlMap?;
      if (keywordsComponent != null) {
        keywords = keywordsComponent.map(
          (lang, keywordList) => MapEntry(
            lang as String,
            (keywordList as YamlList)
                .nodes
                .where((e) => e.value != null)
                .map<String>((e) => e.value.toString())
                .toList(),
          ),
        );
      }

      final screenshots = <AppstreamScreenshot>[];
      final screenshotsComponent = component['Screenshots'];
      if (screenshotsComponent != null) {
        if (screenshotsComponent is! YamlList) {
          throw FormatException('Invalid Screenshots type');
        }
        for (final screenshot in screenshotsComponent) {
          final isDefault = screenshot['default'] as bool? ?? 'false' == 'true';
          final caption = screenshot['caption'];
          final images = <AppstreamImage>[];
          final thumbnails = screenshot['thumbnails'] as YamlList?;
          if (thumbnails != null) {
            for (final thumbnail in thumbnails) {
              final url = thumbnail['url'] as String?;
              if (url == null) {
                throw FormatException('Image missing Url');
              }
              final width = thumbnail['width'] as int?;
              final height = thumbnail['height'] as int?;
              final lang = thumbnail['lang'] as String?;
              images.add(
                AppstreamImage(
                  type: AppstreamImageType.thumbnail,
                  url: _makeUrl(mediaBaseUrl, url),
                  width: width,
                  height: height,
                  lang: lang,
                ),
              );
            }
          }
          final sourceImage = screenshot['source-image'];
          if (sourceImage != null) {
            final url = sourceImage['url'] as String?;
            if (url == null) {
              throw FormatException('Image missing Url');
            }
            final width = sourceImage['width'] as int?;
            final height = sourceImage['height'] as int?;
            final lang = sourceImage['lang'] as String?;
            images.add(
              AppstreamImage(
                type: AppstreamImageType.source,
                url: _makeUrl(mediaBaseUrl, url),
                width: width,
                height: height,
                lang: lang,
              ),
            );
          }
          screenshots.add(
            AppstreamScreenshot(
              images: images,
              caption: caption != null
                  ? _parseYamlTranslatedString(caption)
                  : const {},
              isDefault: isDefault,
            ),
          );
        }
      }

      final compulsoryForDesktops = <String>[];
      final compulsoryForDesktopsComponent = component['CompulsoryForDesktops'];
      if (compulsoryForDesktopsComponent != null) {
        if (compulsoryForDesktopsComponent is! YamlList) {
          throw FormatException('Invalid CompulsoryForDesktops type');
        }
        compulsoryForDesktops
            .addAll(compulsoryForDesktopsComponent.cast<String>());
      }

      final releases = <AppstreamRelease>[];
      final releasesComponent = component['Releases'] as YamlList?;
      if (releasesComponent != null) {
        for (final release in releasesComponent) {
          if (release is! YamlMap) {
            throw FormatException('Invalid release type');
          }
          final version = release['version'];
          DateTime? date;
          final dateAttribute = release['date'] as String?;
          final unixTimestamp = release['unix-timestamp'] as int?;
          if (unixTimestamp != null) {
            date = DateTime.fromMillisecondsSinceEpoch(
              unixTimestamp * 1000,
              isUtc: true,
            );
          } else if (dateAttribute != null) {
            date = DateTime.parse(dateAttribute);
          }
          AppstreamReleaseType? type;
          final typeName = release['type'] as String?;
          if (typeName != null) {
            type = _parseReleaseType(typeName);
          }
          AppstreamReleaseUrgency? urgency;
          final urgencyName = release['urgency'] as String?;
          if (urgencyName != null) {
            urgency = _parseReleaseUrgency(urgencyName);
          }
          final description = release['description'];
          final url = release['url']?['details'] as String?;
          final issues = <AppstreamIssue>[];
          final issuesComponent = release['issues'];
          if (issuesComponent != null) {
            if (issuesComponent is! YamlList) {
              throw FormatException('Invalid issues type');
            }
            for (final issue in issuesComponent) {
              if (issue is! YamlMap) {
                throw FormatException('Invalid issue type');
              }
              final id = issue['id'] as String?;
              if (id == null) {
                throw FormatException('Issue missing id');
              }
              AppstreamIssueType? type;
              final typeName = issue['type'] as String?;
              if (typeName != null) {
                type = _parseIssueType(typeName);
              }
              final url = issue['url'] as String?;
              issues.add(
                AppstreamIssue(
                  id,
                  type: type ?? AppstreamIssueType.generic,
                  url: url,
                ),
              );
            }
          }
          releases.add(
            AppstreamRelease(
              version: _parseYamlVersion(version),
              date: date,
              type: type ?? AppstreamReleaseType.stable,
              urgency: urgency ?? AppstreamReleaseUrgency.medium,
              description: description != null
                  ? _parseYamlTranslatedString(description)
                  : const {},
              url: url,
              issues: issues,
            ),
          );
        }
      }

      final provides = <AppstreamProvides>[];
      final providesComponent = component['Provides'] as YamlMap?;
      if (providesComponent != null) {
        for (final type in providesComponent.keys) {
          final values = providesComponent[type] as YamlList?;
          if (values is! YamlList) {
            throw FormatException('Invalid $type provides');
          }
          switch (type) {
            case 'mediatypes':
            case 'mimetypes':
              provides.addAll(
                values.map((e) => AppstreamProvidesMediatype(e as String)),
              );
              break;
            case 'libraries':
              provides.addAll(
                values.map((e) => AppstreamProvidesLibrary(e as String)),
              );
              break;
            case 'binaries':
              provides.addAll(
                values.map((e) => AppstreamProvidesBinary(e as String)),
              );
              break;
            case 'fonts':
              for (final fontComponent in values) {
                if (fontComponent is! YamlMap) {
                  throw FormatException('Invalid font provides');
                }
                final name = fontComponent['name'] as String?;
                if (name == null) {
                  throw FormatException('Missing font name');
                }
                provides.add(AppstreamProvidesFont(name));
              }
              break;
            case 'firmware':
              for (final firmwareComponent in values) {
                if (firmwareComponent is! YamlMap) {
                  throw FormatException('Invalid firmware provides');
                }
                final type = firmwareComponent['type'];
                switch (type) {
                  case 'runtime':
                    final file = firmwareComponent['file'] as String?;
                    if (file == null) {
                      throw FormatException('Missing firmware file');
                    }
                    provides.add(
                      AppstreamProvidesFirmware(
                        AppstreamFirmwareType.runtime,
                        file,
                      ),
                    );
                    break;
                  case 'flashed':
                    final guid = firmwareComponent['guid'] as String?;
                    if (guid == null) {
                      throw FormatException('Missing firmware guid');
                    }
                    provides.add(
                      AppstreamProvidesFirmware(
                        AppstreamFirmwareType.flashed,
                        guid,
                      ),
                    );
                    break;
                }
              }
              break;
            case 'python2':
              for (final moduleName in values) {
                provides.add(AppstreamProvidesPython2(moduleName as String));
              }
              break;
            case 'python3':
              for (final moduleName in values) {
                provides.add(AppstreamProvidesPython3(moduleName as String));
              }
              break;
            case 'modaliases':
              for (final modalias in values) {
                provides.add(AppstreamProvidesModalias(modalias as String));
              }
              break;
            case 'dbus':
              for (final dbusComponent in values) {
                if (dbusComponent is! YamlMap) {
                  throw FormatException('Invalid dbus provides');
                }
                final type = dbusComponent['type'] as String?;
                if (type == null) {
                  throw FormatException('Missing DBus bus type');
                }
                final service = dbusComponent['service'] as String?;
                if (service == null) {
                  throw FormatException('Missing DBus service name');
                }
                provides
                    .add(AppstreamProvidesDBus(_parseDBusType(type), service));
              }
              break;
            case 'ids':
              provides
                  .addAll(values.map((e) => AppstreamProvidesId(e as String)));
              break;
          }
        }
      }

      final languages = <AppstreamLanguage>[];
      final languagesComponent = component['Languages'];
      if (languagesComponent != null) {
        if (languagesComponent is! YamlList) {
          throw FormatException('Invalid Languages type');
        }

        for (final language in languagesComponent) {
          if (language is! YamlMap) {
            throw FormatException('Invalid language type');
          }
          final locale = language['locale'] as String?;
          if (locale == null) {
            throw FormatException('Missing language locale');
          }
          final percentage = language['percentage'] as int?;
          languages.add(AppstreamLanguage(locale, percentage: percentage));
        }
      }

      final contentRatings = <String, Map<String, AppstreamContentRating>>{};
      final contentRatingComponent = component['ContentRating'] as YamlMap?;
      if (contentRatingComponent != null) {
        for (final type in contentRatingComponent.keys) {
          contentRatings[type as String] =
              (contentRatingComponent[type] as YamlMap)
                  .map<String, AppstreamContentRating>(
            (key, value) =>
                MapEntry(key as String, _parseContentRating(value as String)),
          );
        }
      }

      final bundles = <AppstreamBundle>[];
      final bundlesComponent = component['Bundles'] as YamlList?;
      if (bundlesComponent != null) {
        for (final bundle in bundlesComponent) {
          if (bundle is! YamlMap) {
            throw FormatException('Invalid bundle type');
          }
          final typeName = bundle['type'] as String?;
          final type = typeName != null
              ? _parseBundleType(typeName)
              : AppstreamBundleType.unknown;
          bundles.add(AppstreamBundle(bundle['id'] as String, type: type));
        }
      }

      final custom = <Map<String, String>>[];
      final customComponent = component['Custom'] as YamlNode?;
      if (customComponent is YamlList) {
        for (final entry in customComponent) {
          if (entry is YamlMap) {
            final key = entry.keys.first as String;
            final value = entry.values.first as String;
            custom.add({key: value});
          }
        }
      }

      components.add(
        AppstreamComponent(
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
          custom: custom,
          contentRatings: contentRatings,
        ),
      );
    }

    return AppstreamCollection(
      version: _parseYamlVersion(version)!,
      origin: origin,
      architecture: architecture,
      priority: priority,
      components: components,
    );
  }

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
  final value = <String, String>{};
  for (final element in parent.children
      .whereType<XmlElement>()
      .where((e) => e.name.local == name)) {
    final lang =
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
        'runtime': AppstreamComponentType.runtime,
      }[typeName] ??
      AppstreamComponentType.unknown;
}

AppstreamUrlType _parseUrlType(String typeName) {
  final type = {
    'homepage': AppstreamUrlType.homepage,
    'bugtracker': AppstreamUrlType.bugtracker,
    'faq': AppstreamUrlType.faq,
    'help': AppstreamUrlType.help,
    'donation': AppstreamUrlType.donation,
    'translate': AppstreamUrlType.translate,
    'contact': AppstreamUrlType.contact,
    'vcs-browser': AppstreamUrlType.vcsBrowser,
    'contribute': AppstreamUrlType.contribute,
  }[typeName];
  if (type == null) {
    throw FormatException("Unknown url type '$typeName'");
  }
  return type;
}

AppstreamReleaseType _parseReleaseType(String typeName) {
  final type = {
    'stable': AppstreamReleaseType.stable,
    'development': AppstreamReleaseType.development,
  }[typeName];
  if (type == null) {
    throw FormatException("Unknown release type '$typeName'");
  }
  return type;
}

AppstreamReleaseUrgency _parseReleaseUrgency(String urgencyName) {
  final urgency = {
    'low': AppstreamReleaseUrgency.low,
    'medium': AppstreamReleaseUrgency.medium,
    'high': AppstreamReleaseUrgency.high,
    'critical': AppstreamReleaseUrgency.critical,
  }[urgencyName];
  if (urgency == null) {
    throw FormatException("Unknown release urgency '$urgencyName'");
  }
  return urgency;
}

AppstreamIssueType _parseIssueType(String typeName) {
  final type = {
    'generic': AppstreamIssueType.generic,
    'cve': AppstreamIssueType.cve,
  }[typeName];
  if (type == null) {
    throw FormatException("Unknown issue type '$typeName'");
  }
  return type;
}

AppstreamDBusType _parseDBusType(String typeName) {
  final type = {
    'user': AppstreamDBusType.user,
    'session': AppstreamDBusType.session,
    'system': AppstreamDBusType.system,
  }[typeName];
  if (type == null) {
    throw FormatException("Unknown DBus type '$typeName'");
  }
  return type;
}

AppstreamBundleType _parseBundleType(String typeName) {
  final type = {
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
  final rating = {
    'none': AppstreamContentRating.none,
    'mild': AppstreamContentRating.mild,
    'moderate': AppstreamContentRating.moderate,
    'intense': AppstreamContentRating.intense,
  }[ratingName];
  if (rating == null) {
    throw FormatException("Unknown content rating '$ratingName'");
  }
  return rating;
}
