import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:appstream/appstream.dart';
import 'package:test/test.dart';

void main() {
  test('collection - empty xml', () async {
    expect(() => AppstreamCollection.fromXml(''), throwsFormatException);
  });

  test('collection - invalid xml', () async {
    expect(
      () => AppstreamCollection.fromXml('<foo></foo>'),
      throwsFormatException,
    );
  });

  test('collection - empty - xml', () async {
    final collection = AppstreamCollection.fromXml(
      '<components version="0.12" origin="ubuntu-hirsute-main"/>',
    );
    expect(collection.version, equals('0.12'));
    expect(collection.origin, equals('ubuntu-hirsute-main'));
    expect(collection.architecture, isNull);
    expect(collection.priority, isNull);
    expect(collection.components, isEmpty);
  });

  test('collection - architecture - xml', () async {
    final collection = AppstreamCollection.fromXml(
      '<components version="0.12" origin="ubuntu-hirsute-main" architecture="arm64"/>',
    );
    expect(collection.architecture, equals('arm64'));
  });

  test('collection - single - xml', () async {
    final collection = AppstreamCollection.fromXml(
        '''<components version="0.12" origin="ubuntu-hirsute-main">
  <component type="console-application">
    <id>com.example.Hello</id>
    <pkgname>hello</pkgname>
    <name>Hello World</name>
    <summary>A simple example application</summary>
  </component>
</components>
''');
    expect(collection.components, hasLength(1));
    final component = collection.components[0];
    expect(component.id, equals('com.example.Hello'));
    expect(component.type, equals(AppstreamComponentType.consoleApplication));
    expect(component.package, equals('hello'));
    expect(component.name, equals({'C': 'Hello World'}));
    expect(component.summary, equals({'C': 'A simple example application'}));
    expect(component.description, isEmpty);
    expect(component.developerName, isEmpty);
    expect(component.projectLicense, isNull);
    expect(component.projectGroup, isNull);
    expect(component.icons, isEmpty);
    expect(component.urls, isEmpty);
    expect(component.categories, isEmpty);
    expect(component.keywords, isEmpty);
    expect(component.screenshots, isEmpty);
    expect(component.compulsoryForDesktops, isEmpty);
    expect(component.provides, isEmpty);
    expect(component.releases, isEmpty);
    expect(component.languages, isEmpty);
    expect(component.contentRatings, isEmpty);
  });

  test('collection - optional fields - xml', () async {
    final collection = AppstreamCollection.fromXml(
        '''<components version="0.12" origin="ubuntu-hirsute-main">
  <component type="console-application">
    <id>com.example.Hello</id>
    <pkgname>hello</pkgname>
    <name>Hello World</name>
    <summary>A simple example application</summary>
    <description><p>The <b>best</b> thing since sliced bread</p></description>
    <developer_name>The Developer</developer_name>
    <project_license>GPL-3</project_license>
    <project_group>GNOME</project_group>
    <compulsory_for_desktop>GNOME</compulsory_for_desktop>
    <compulsory_for_desktop>KDE</compulsory_for_desktop>
  </component>
</components>
''');
    expect(collection.components, hasLength(1));
    final component = collection.components[0];
    expect(
      component.description,
      equals({'C': '<p>The <b>best</b> thing since sliced bread</p>'}),
    );
    expect(component.developerName, equals({'C': 'The Developer'}));
    expect(component.projectLicense, equals('GPL-3'));
    expect(component.projectGroup, equals('GNOME'));
    expect(component.compulsoryForDesktops, equals(['GNOME', 'KDE']));
  });

  test('collection - icons - xml', () async {
    final collection = AppstreamCollection.fromXml(
        '''<components version="0.12" origin="ubuntu-hirsute-main">
  <component type="console-application">
    <id>com.example.Hello</id>
    <pkgname>hello</pkgname>
    <name>Hello World</name>
    <summary>A simple example application</summary>
    <icon type="stock">stock-name</icon>
    <icon type="cached" width="8" height="16">icon.png</icon>
    <icon type="local" width="32" height="48">/path/to/icon.png</icon>
    <icon type="remote" width="64" height="128">https://example.com/icon.png</icon>
  </component>
</components>
''');
    expect(collection.components, hasLength(1));
    final component = collection.components[0];
    expect(component.icons, hasLength(4));
    expect(
      component.icons,
      equals([
        AppstreamStockIcon('stock-name'),
        AppstreamCachedIcon('icon.png', width: 8, height: 16),
        AppstreamLocalIcon('/path/to/icon.png', width: 32, height: 48),
        AppstreamRemoteIcon(
          'https://example.com/icon.png',
          width: 64,
          height: 128,
        ),
      ]),
    );
  });

  test('collection - urls - xml', () async {
    final collection = AppstreamCollection.fromXml(
        '''<components version="0.12" origin="ubuntu-hirsute-main">
  <component type="console-application">
    <id>com.example.Hello</id>
    <pkgname>hello</pkgname>
    <name>Hello World</name>
    <summary>A simple example application</summary>
    <url type="homepage">https://example.com</url>
    <url type="help">https://example.com/help</url>
    <url type="contact"></url>
  </component>
</components>
''');
    expect(collection.components, hasLength(1));
    final component = collection.components[0];
    expect(
      component.urls,
      equals([
        AppstreamUrl('https://example.com', type: AppstreamUrlType.homepage),
        AppstreamUrl('https://example.com/help', type: AppstreamUrlType.help),
        AppstreamUrl('', type: AppstreamUrlType.contact),
      ]),
    );
  });

  test('collection - launchables - xml', () async {
    final collection = AppstreamCollection.fromXml(
        '''<components version="0.12" origin="ubuntu-hirsute-main">
  <component type="console-application">
    <id>com.example.Hello</id>
    <pkgname>hello</pkgname>
    <name>Hello World</name>
    <summary>A simple example application</summary>
    <launchable type="desktop-id">com.example.Hello1</launchable>
    <launchable type="desktop-id">com.example.Hello2</launchable>
    <launchable type="url">https://example.com/launch</launchable>
  </component>
</components>
''');
    expect(collection.components, hasLength(1));
    final component = collection.components[0];
    expect(
      component.launchables,
      equals([
        AppstreamLaunchableDesktopId('com.example.Hello1'),
        AppstreamLaunchableDesktopId('com.example.Hello2'),
        AppstreamLaunchableUrl('https://example.com/launch'),
      ]),
    );
  });

  test('collection - categories - xml', () async {
    final collection = AppstreamCollection.fromXml(
        '''<components version="0.12" origin="ubuntu-hirsute-main">
  <component type="console-application">
    <id>com.example.Hello</id>
    <pkgname>hello</pkgname>
    <name>Hello World</name>
    <summary>A simple example application</summary>
    <categories>
      <category>Game</category>
      <category>ArcadeGame</category>
    </categories>
  </component>
</components>
''');
    expect(collection.components, hasLength(1));
    final component = collection.components[0];
    expect(component.categories, equals(['Game', 'ArcadeGame']));
  });

  test('collection - keywords - xml', () async {
    final collection = AppstreamCollection.fromXml(
        '''<components version="0.12" origin="ubuntu-hirsute-main">
  <component type="console-application">
    <id>com.example.Hello</id>
    <pkgname>hello</pkgname>
    <name>Hello World</name>
    <summary>A simple example application</summary>
    <keywords>
      <keyword>Hello</keyword>
      <keyword>Welcome</keyword>
    </keywords>
    <keywords xml:lang="de_DE">
      <keyword>Hallo</keyword>
      <keyword>Wilkommen</keyword>
    </keywords>
  </component>
</components>
''');
    expect(collection.components, hasLength(1));
    final component = collection.components[0];
    expect(
      component.keywords,
      equals({
        'C': ['Hello', 'Welcome'],
        'de_DE': ['Hallo', 'Wilkommen'],
      }),
    );
  });

  test('collection - screenshot - xml', () async {
    final collection = AppstreamCollection.fromXml(
        '''<components version="0.12" origin="ubuntu-hirsute-main">
  <component type="console-application">
    <id>com.example.Hello</id>
    <pkgname>hello</pkgname>
    <name>Hello World</name>
    <summary>A simple example application</summary>
    <screenshot>
      <caption>A screenshot</caption>
      <image type="thumbnail" width="512" height="384">https://example.com/thumbnail-big.jpg</image>
      <image type="thumbnail" width="256" height="192" xml:lang="en_NZ">https://example.com/thumbnail-small.jpg</image>
      <image type="source" width="1024" height="768">https://example.com/screenshot.jpg</image>
    </screenshot>
  </component>
</components>
''');
    expect(collection.components, hasLength(1));
    final component = collection.components[0];
    expect(
      component.screenshots,
      equals([
        AppstreamScreenshot(
          images: [
            AppstreamImage(
              type: AppstreamImageType.thumbnail,
              url: 'https://example.com/thumbnail-big.jpg',
              width: 512,
              height: 384,
            ),
            AppstreamImage(
              type: AppstreamImageType.thumbnail,
              url: 'https://example.com/thumbnail-small.jpg',
              width: 256,
              height: 192,
              lang: 'en_NZ',
            ),
            AppstreamImage(
              type: AppstreamImageType.source,
              url: 'https://example.com/screenshot.jpg',
              width: 1024,
              height: 768,
            ),
          ],
          caption: {
            'C': 'A screenshot',
          },
        ),
      ]),
    );
  });

  test('collection - screenshots - xml', () async {
    final collection = AppstreamCollection.fromXml(
        '''<components version="0.12" origin="ubuntu-hirsute-main">
  <component type="console-application">
    <id>com.example.Hello</id>
    <pkgname>hello</pkgname>
    <name>Hello World</name>
    <summary>A simple example application</summary>
    <screenshot>
      <image type="source">https://example.com/screenshot1.jpg</image>
    </screenshot>
    <screenshot type="default">
      <image type="source">https://example.com/screenshot2.jpg</image>
    </screenshot>
  </component>
</components>
''');
    expect(collection.components, hasLength(1));
    final component = collection.components[0];
    expect(
      component.screenshots,
      equals([
        AppstreamScreenshot(
          images: [
            AppstreamImage(
              type: AppstreamImageType.source,
              url: 'https://example.com/screenshot1.jpg',
            ),
          ],
        ),
        AppstreamScreenshot(
          images: [
            AppstreamImage(
              type: AppstreamImageType.source,
              url: 'https://example.com/screenshot2.jpg',
            ),
          ],
          isDefault: true,
        ),
      ]),
    );
  });

  test('collection - releases - xml', () async {
    final collection = AppstreamCollection.fromXml(
        '''<components version="0.12" origin="ubuntu-hirsute-main">
  <component type="console-application">
    <id>com.example.Hello</id>
    <pkgname>hello</pkgname>
    <name>Hello World</name>
    <summary>A simple example application</summary>
    <releases>
      <release version="1.2" date="2014-04-12" urgency="high">
        <description>This stable release fixes bugs.</description>
        <url>https://example.com/releases/version-1.2.html</url>
        <issues>
          <issue url="https://github.com/example/example/issues/123">#123</issue>
          <issue type="cve">CVE-2019-123456</issue>
        </issues>
      </release>
      <release version="1.1" type="development" date="2013-10-20"/>
      <release version="1.0" timestamp="1345939200"/>
      <release version="0.9" type="snapshot" date="2012-01-15"/>
    </releases>
  </component>
</components>
''');
    expect(collection.components, hasLength(1));
    final component = collection.components[0];
    expect(
      component.releases,
      equals([
        AppstreamRelease(
          version: '1.2',
          date: DateTime(2014, 4, 12),
          urgency: AppstreamReleaseUrgency.high,
          description: {'C': 'This stable release fixes bugs.'},
          url: 'https://example.com/releases/version-1.2.html',
          issues: [
            AppstreamIssue(
              '#123',
              url: 'https://github.com/example/example/issues/123',
            ),
            AppstreamIssue('CVE-2019-123456', type: AppstreamIssueType.cve),
          ],
        ),
        AppstreamRelease(
          version: '1.1',
          type: AppstreamReleaseType.development,
          date: DateTime(2013, 10, 20),
        ),
        AppstreamRelease(version: '1.0', date: DateTime.utc(2012, 8, 26)),
        AppstreamRelease(
          version: '0.9',
          type: AppstreamReleaseType.snapshot,
          date: DateTime(2012, 1, 15),
        ),
      ]),
    );
  });

  test('collection - provides - xml', () async {
    final collection = AppstreamCollection.fromXml(
        '''<components version="0.12" origin="ubuntu-hirsute-main">
  <component type="console-application">
    <id>com.example.Hello</id>
    <pkgname>hello</pkgname>
    <name>Hello World</name>
    <summary>A simple example application</summary>
    <provides>
      <mediatype>text/html</mediatype>
      <mediatype>image/png</mediatype>
      <library>libhello.so.1</library>
      <binary>hello</binary>
      <font>Hello</font>
      <modalias>usb:*</modalias>
      <firmware type="runtime">hello.fw</firmware>
      <python2>modhello</python2>
      <python3>modhello3</python3>
      <dbus type="system">com.example.Service</dbus>
      <id>com.example.SimpleHello</id>
    </provides>
  </component>
</components>
''');
    expect(collection.components, hasLength(1));
    final component = collection.components[0];
    expect(
      component.provides,
      equals([
        AppstreamProvidesMediatype('text/html'),
        AppstreamProvidesMediatype('image/png'),
        AppstreamProvidesLibrary('libhello.so.1'),
        AppstreamProvidesBinary('hello'),
        AppstreamProvidesFont('Hello'),
        AppstreamProvidesModalias('usb:*'),
        AppstreamProvidesFirmware(AppstreamFirmwareType.runtime, 'hello.fw'),
        AppstreamProvidesPython2('modhello'),
        AppstreamProvidesPython3('modhello3'),
        AppstreamProvidesDBus(
          AppstreamDBusType.system,
          'com.example.Service',
        ),
        AppstreamProvidesId('com.example.SimpleHello'),
      ]),
    );
  });

  test('collection - languages - xml', () async {
    final collection = AppstreamCollection.fromXml(
        '''<components version="0.12" origin="ubuntu-hirsute-main">
  <component type="console-application">
    <id>com.example.Hello</id>
    <pkgname>hello</pkgname>
    <name>Hello World</name>
    <summary>A simple example application</summary>
    <languages>
      <lang>en</lang>
      <lang percentage="42">de</lang>
    </languages>
  </component>
</components>
''');
    expect(collection.components, hasLength(1));
    final component = collection.components[0];
    expect(
      component.languages,
      equals([
        AppstreamLanguage('en'),
        AppstreamLanguage('de', percentage: 42),
      ]),
    );
  });

  test('collection - content-rating - xml', () async {
    final collection = AppstreamCollection.fromXml(
        '''<components version="0.12" origin="ubuntu-hirsute-main">
  <component type="console-application">
    <id>com.example.Hello</id>
    <pkgname>hello</pkgname>
    <name>Hello World</name>
    <summary>A simple example application</summary>
    <content_rating type="oars-1.0">
      <content_attribute id="drugs-alcohol">moderate</content_attribute>
      <content_attribute id="language-humor">mild</content_attribute>
    </content_rating>
  </component>
</components>
''');
    expect(collection.components, hasLength(1));
    final component = collection.components[0];
    expect(
      component.contentRatings,
      equals({
        'oars-1.0': {
          'drugs-alcohol': AppstreamContentRating.moderate,
          'language-humor': AppstreamContentRating.mild,
        },
      }),
    );
  });

  test('collection - bundles - xml', () async {
    final collection = AppstreamCollection.fromXml(
        '''<components version="0.12" origin="ubuntu-hirsute-main">
  <component type="console-application">
    <id>com.example.Hello</id>
    <pkgname>hello</pkgname>
    <name>Hello World</name>
    <summary>A simple example application</summary>
    <bundle type="limba">foobar-1.0.2</bundle>
  </component>
</components>
''');
    expect(collection.components, hasLength(1));
    final component = collection.components[0];
    expect(
      component.bundles,
      equals([
        AppstreamBundle('foobar-1.0.2', type: AppstreamBundleType.limba),
      ]),
    );
  });

  test('collection - custom - xml', () async {
    final collection = AppstreamCollection.fromXml(
        '''<components version="0.12" origin="ubuntu-hirsute-main">
  <component type="console-application">
    <id>com.example.Hello</id>
    <pkgname>hello</pkgname>
    <name>Hello World</name>
    <summary>A simple example application</summary>
    <custom>
      <value key="MyCorp::app_color">#FF0000</value>
      <value key="MyCorp::special_id">284fd262-6870-42a6-89a4-b189d3109e3e</value>
    </custom>
  </component>
</components>
''');
    expect(collection.components, hasLength(1));
    final component = collection.components[0];
    expect(
      component.custom,
      equals([
        {'MyCorp::app_color': '#FF0000'},
        {'MyCorp::special_id': '284fd262-6870-42a6-89a4-b189d3109e3e'},
      ]),
    );
  });

  test('collection - locales - xml', () async {
    const xml = '''<components version="0.12" origin="ubuntu-hirsute-main">
  <component type="desktop-application">
    <id>com.example.Hello</id>
    <pkgname>hello</pkgname>
    <name>Hello</name>
    <name xml:lang="de_DE">Hallo</name>
    <name xml:lang="fr">Bonjour</name>
    <summary>Says hello</summary>
    <summary xml:lang="de_DE">Sagt hallo</summary>
    <summary xml:lang="fr">Dit bonjour</summary>
    <description><p>Greets the world.</p></description>
    <description xml:lang="de_DE"><p>Grüßt die Welt.</p></description>
    <description xml:lang="fr"><p>Salue le monde.</p></description>
    <developer_name>The Developer</developer_name>
    <developer_name xml:lang="de_DE">Der Entwickler</developer_name>
    <developer_name xml:lang="fr">Le développeur</developer_name>
    <keywords>
      <keyword>greeting</keyword>
    </keywords>
    <keywords xml:lang="de_DE">
      <keyword>Gruß</keyword>
    </keywords>
    <keywords xml:lang="fr">
      <keyword>salutation</keyword>
    </keywords>
    <screenshots>
      <screenshot type="default">
        <caption>Main window</caption>
        <caption xml:lang="de_DE">Hauptfenster</caption>
        <caption xml:lang="fr">Fenêtre principale</caption>
        <image type="source">https://example.com/screenshot.png</image>
      </screenshot>
    </screenshots>
    <releases>
      <release version="1.0" date="2014-04-12">
        <description><p>First release.</p></description>
        <description xml:lang="de_DE"><p>Erste Version.</p></description>
        <description xml:lang="fr"><p>Première version.</p></description>
      </release>
    </releases>
  </component>
</components>
''';

    final unfiltered = AppstreamCollection.fromXml(xml).components.single;
    expect(
      unfiltered.name,
      equals({'C': 'Hello', 'de_DE': 'Hallo', 'fr': 'Bonjour'}),
    );
    expect(
      unfiltered.summary,
      equals({'C': 'Says hello', 'de_DE': 'Sagt hallo', 'fr': 'Dit bonjour'}),
    );
    expect(
      unfiltered.description,
      equals({
        'C': '<p>Greets the world.</p>',
        'de_DE': '<p>Grüßt die Welt.</p>',
        'fr': '<p>Salue le monde.</p>',
      }),
    );
    expect(
      unfiltered.developerName,
      equals({
        'C': 'The Developer',
        'de_DE': 'Der Entwickler',
        'fr': 'Le développeur',
      }),
    );
    expect(
      unfiltered.keywords,
      equals({
        'C': ['greeting'],
        'de_DE': ['Gruß'],
        'fr': ['salutation'],
      }),
    );
    expect(
      unfiltered.screenshots.single.caption,
      equals({
        'C': 'Main window',
        'de_DE': 'Hauptfenster',
        'fr': 'Fenêtre principale',
      }),
    );
    expect(
      unfiltered.releases.single.description,
      equals({
        'C': '<p>First release.</p>',
        'de_DE': '<p>Erste Version.</p>',
        'fr': '<p>Première version.</p>',
      }),
    );

    final filtered =
        AppstreamCollection.fromXml(xml, locales: ['de_DE']).components.single;
    expect(filtered.name, equals({'C': 'Hello', 'de_DE': 'Hallo'}));
    expect(
      filtered.summary,
      equals({'C': 'Says hello', 'de_DE': 'Sagt hallo'}),
    );
    expect(
      filtered.description,
      equals({
        'C': '<p>Greets the world.</p>',
        'de_DE': '<p>Grüßt die Welt.</p>',
      }),
    );
    expect(
      filtered.developerName,
      equals({'C': 'The Developer', 'de_DE': 'Der Entwickler'}),
    );
    expect(
      filtered.keywords,
      equals({
        'C': ['greeting'],
        'de_DE': ['Gruß'],
      }),
    );
    expect(
      filtered.screenshots.single.caption,
      equals({'C': 'Main window', 'de_DE': 'Hauptfenster'}),
    );
    expect(
      filtered.releases.single.description,
      equals({'C': '<p>First release.</p>', 'de_DE': '<p>Erste Version.</p>'}),
    );

    final cOnly =
        AppstreamCollection.fromXml(xml, locales: []).components.single;
    expect(cOnly.name, equals({'C': 'Hello'}));
    expect(cOnly.summary, equals({'C': 'Says hello'}));
    expect(cOnly.description, equals({'C': '<p>Greets the world.</p>'}));
    expect(cOnly.developerName, equals({'C': 'The Developer'}));
    expect(
      cOnly.keywords,
      equals({
        'C': ['greeting'],
      }),
    );
    expect(cOnly.screenshots.single.caption, equals({'C': 'Main window'}));
    expect(
      cOnly.releases.single.description,
      equals({'C': '<p>First release.</p>'}),
    );
  });

  test('collection - empty yaml', () async {
    expect(() => AppstreamCollection.fromYaml(''), throwsFormatException);
  });

  test('collection - invalid yaml', () async {
    expect(
      () => AppstreamCollection.fromYaml('---\nFile: NotTheRightThing\n'),
      throwsFormatException,
    );
  });

  test('collection - yaml with duplicate mapping keys', () async {
    final collection = AppstreamCollection.fromYaml("""---
File: DEP-11
Version: '0.12'
Origin: ubuntu-hirsute-main
---
Type: console-application
ID: com.example.Hello
Package: hello
Name:
  C: Hello World
Summary:
  C: A simple example application
ContentRating:
  oars-1.1: {}
  oars-1.1: {}
""");
    expect(collection.components, isEmpty);
  });

  test('collection - empty - yaml', () async {
    final collection = AppstreamCollection.fromYaml("""---
File: DEP-11
Version: '0.12'
Origin: ubuntu-hirsute-main
""");
    expect(collection.version, equals('0.12'));
    expect(collection.origin, equals('ubuntu-hirsute-main'));
    expect(collection.architecture, isNull);
    expect(collection.priority, isNull);
    expect(collection.components, isEmpty);
  });

  test('collection - architecture - yaml', () async {
    final collection = AppstreamCollection.fromYaml("""---
File: DEP-11
Version: '0.12'
Origin: ubuntu-hirsute-main
Architecture: arm64
""");
    expect(collection.architecture, equals('arm64'));
  });

  test('collection - priority - yaml', () async {
    final collection = AppstreamCollection.fromYaml("""---
File: DEP-11
Version: '0.12'
Origin: ubuntu-hirsute-main
Priority: 42
""");
    expect(collection.priority, equals(42));
  });

  test('collection - single - yaml', () async {
    final collection = AppstreamCollection.fromYaml("""---
File: DEP-11
Version: '0.12'
Origin: ubuntu-hirsute-main
---
Type: console-application
ID: com.example.Hello
Package: hello
Name:
  C: Hello World
Summary:
  C: A simple example application
""");
    expect(collection.components, hasLength(1));
    final component = collection.components[0];
    expect(component.id, equals('com.example.Hello'));
    expect(component.type, equals(AppstreamComponentType.consoleApplication));
    expect(component.package, equals('hello'));
    expect(component.name, equals({'C': 'Hello World'}));
    expect(component.summary, equals({'C': 'A simple example application'}));
    expect(component.description, isEmpty);
    expect(component.developerName, isEmpty);
    expect(component.projectLicense, isNull);
    expect(component.projectGroup, isNull);
    expect(component.icons, isEmpty);
    expect(component.urls, isEmpty);
    expect(component.categories, isEmpty);
    expect(component.keywords, isEmpty);
    expect(component.screenshots, isEmpty);
    expect(component.compulsoryForDesktops, isEmpty);
    expect(component.provides, isEmpty);
    expect(component.releases, isEmpty);
    expect(component.languages, isEmpty);
    expect(component.contentRatings, isEmpty);
  });

  test('collection - optional fields - yaml', () async {
    final collection = AppstreamCollection.fromYaml("""---
File: DEP-11
Version: '0.12'
Origin: ubuntu-hirsute-main
---
Type: console-application
ID: com.example.Hello
Package: hello
Name:
  C: Hello World
Summary:
  C: A simple example application
Description:
  C: >-
    <p>The <b>best</b> thing since sliced bread</p>
DeveloperName:
  C: The Developer
ProjectLicense: GPL-3
ProjectGroup: GNOME
CompulsoryForDesktops:
- GNOME
- KDE
""");
    expect(collection.components, hasLength(1));
    final component = collection.components[0];
    expect(
      component.description,
      equals({'C': '<p>The <b>best</b> thing since sliced bread</p>'}),
    );
    expect(component.developerName, equals({'C': 'The Developer'}));
    expect(component.projectLicense, equals('GPL-3'));
    expect(component.projectGroup, equals('GNOME'));
    expect(component.compulsoryForDesktops, equals(['GNOME', 'KDE']));
  });

  test('collection - translated strings (non-string values) - yaml', () async {
    final collection = AppstreamCollection.fromYaml("""---
File: DEP-11
Version: '0.12'
Origin: ubuntu-hirsute-main
---
Type: desktop-application
ID: com.example.Game
Package: game
Name:
  C: 2048
  de_DE:
Summary:
  C: A sliding tile puzzle
""");
    final component = collection.components.single;
    expect(component.name, equals({'C': '2048'}));
  });

  test('collection - icons - yaml', () async {
    final collection = AppstreamCollection.fromYaml("""---
File: DEP-11
Version: '0.12'
Origin: ubuntu-hirsute-main
MediaBaseUrl: https://example.com/images
---
Type: console-application
ID: com.example.Hello
Package: hello
Name:
  C: Hello World
Summary:
  C: A simple example application
Icon:
  stock: stock-name
  cached:
  - name: icon.png
    width: 8
    height: 16
  local:
  - name: /path/to/icon.png
    width: 32
    height: 48
  remote:
  - url: https://example.com/icon.png
    width: 64
    height: 128
  - url: icon-big.png
    width: 256
    height: 256
""");
    expect(collection.components, hasLength(1));
    final component = collection.components[0];
    expect(component.id, equals('com.example.Hello'));
    expect(component.type, equals(AppstreamComponentType.consoleApplication));
    expect(component.package, equals('hello'));
    expect(component.name, equals({'C': 'Hello World'}));
    expect(component.summary, equals({'C': 'A simple example application'}));
    expect(
      component.icons,
      equals([
        AppstreamStockIcon('stock-name'),
        AppstreamCachedIcon('icon.png', width: 8, height: 16),
        AppstreamLocalIcon('/path/to/icon.png', width: 32, height: 48),
        AppstreamRemoteIcon(
          'https://example.com/icon.png',
          width: 64,
          height: 128,
        ),
        AppstreamRemoteIcon(
          'https://example.com/images/icon-big.png',
          width: 256,
          height: 256,
        ),
      ]),
    );
  });

  test('collection - urls - yaml', () async {
    final collection = AppstreamCollection.fromYaml("""---
File: DEP-11
Version: '0.12'
Origin: ubuntu-hirsute-main
---
Type: console-application
ID: com.example.Hello
Package: hello
Name:
  C: Hello World
Summary:
  C: A simple example application
Url:
  homepage: https://example.com
  help: https://example.com/help
  contact:
""");
    expect(collection.components, hasLength(1));
    final component = collection.components[0];
    expect(
      component.urls,
      equals([
        AppstreamUrl('https://example.com', type: AppstreamUrlType.homepage),
        AppstreamUrl('https://example.com/help', type: AppstreamUrlType.help),
        AppstreamUrl('', type: AppstreamUrlType.contact),
      ]),
    );
  });

  test('collection - launchables - yaml', () async {
    final collection = AppstreamCollection.fromYaml("""---
File: DEP-11
Version: '0.12'
Origin: ubuntu-hirsute-main
---
Type: console-application
ID: com.example.Hello
Package: hello
Name:
  C: Hello World
Summary:
  C: A simple example application
Launchable:
  desktop-id:
    - com.example.Hello1
    - com.example.Hello2
  url:
    - https://example.com/launch
""");
    expect(collection.components, hasLength(1));
    final component = collection.components[0];
    expect(
      component.launchables,
      equals([
        AppstreamLaunchableDesktopId('com.example.Hello1'),
        AppstreamLaunchableDesktopId('com.example.Hello2'),
        AppstreamLaunchableUrl('https://example.com/launch'),
      ]),
    );
  });

  test('collection - categories - yaml', () async {
    final collection = AppstreamCollection.fromYaml("""---
File: DEP-11
Version: '0.12'
Origin: ubuntu-hirsute-main
---
Type: console-application
ID: com.example.Hello
Package: hello
Name:
  C: Hello World
Summary:
  C: A simple example application
Categories:
  - Game
  - ArcadeGame
""");
    expect(collection.components, hasLength(1));
    final component = collection.components[0];
    expect(component.categories, equals(['Game', 'ArcadeGame']));
  });

  test('collection - keywords - yaml', () async {
    final collection = AppstreamCollection.fromYaml("""---
File: DEP-11
Version: '0.12'
Origin: ubuntu-hirsute-main
---
Type: console-application
ID: com.example.Hello
Package: hello
Name:
  C: Hello World
Summary:
  C: A simple example application
Keywords:
  C:
    - Hello
    - Welcome
  de_DE:
    - Hallo
    - Wilkommen
""");
    expect(collection.components, hasLength(1));
    final component = collection.components[0];
    expect(
      component.keywords,
      equals({
        'C': ['Hello', 'Welcome'],
        'de_DE': ['Hallo', 'Wilkommen'],
      }),
    );
  });

  test('collection - keywords (null values) - yaml', () async {
    // Test for https://github.com/canonical/appstream.dart/issues/22
    final collection = AppstreamCollection.fromYaml("""---
File: DEP-11
Version: '0.12'
Origin: ubuntu-hirsute-main
---
Type: console-application
ID: com.example.Hello
Package: hello
Name:
  C: Hello World
Summary:
  C: A simple example application
Keywords:
  C:
    - Hello
    - Welcome
  de_DE:
    - Hallo
    -
    - Wilkommen
""");
    expect(collection.components, hasLength(1));
    final component = collection.components[0];
    expect(
      component.keywords,
      equals({
        'C': ['Hello', 'Welcome'],
        'de_DE': ['Hallo', 'Wilkommen'],
      }),
    );
  });

  test('collection - screenshot - yaml', () async {
    final collection = AppstreamCollection.fromYaml("""---
File: DEP-11
Version: '0.12'
Origin: ubuntu-hirsute-main
MediaBaseUrl: https://example.com/images
---
Type: console-application
ID: com.example.Hello
Package: hello
Name:
  C: Hello World
Summary:
  C: A simple example application
Screenshots:
- caption:
    C: A screenshot
  thumbnails:
  - url: https://example.com/thumbnail-big.jpg
    width: 512
    height: 384
  - url: thumbnail-small.jpg
    width: 256
    height: 192
    lang: en_NZ
  source-image:
    url: screenshot.jpg
    width: 1024
    height: 768
""");
    expect(collection.components, hasLength(1));
    final component = collection.components[0];
    expect(
      component.screenshots,
      equals([
        AppstreamScreenshot(
          images: [
            AppstreamImage(
              type: AppstreamImageType.thumbnail,
              url: 'https://example.com/thumbnail-big.jpg',
              width: 512,
              height: 384,
            ),
            AppstreamImage(
              type: AppstreamImageType.thumbnail,
              url: 'https://example.com/images/thumbnail-small.jpg',
              width: 256,
              height: 192,
              lang: 'en_NZ',
            ),
            AppstreamImage(
              type: AppstreamImageType.source,
              url: 'https://example.com/images/screenshot.jpg',
              width: 1024,
              height: 768,
            ),
          ],
          caption: {
            'C': 'A screenshot',
          },
        ),
      ]),
    );
  });

  test('collection - screenshots - yaml', () async {
    final collection = AppstreamCollection.fromYaml("""---
File: DEP-11
Version: '0.12'
Origin: ubuntu-hirsute-main
---
Type: console-application
ID: com.example.Hello
Package: hello
Name:
  C: Hello World
Summary:
  C: A simple example application
Screenshots:
- source-image:
    url: https://example.com/screenshot1.jpg
- default: true
  source-image:
    url: https://example.com/screenshot2.jpg
""");
    expect(collection.components, hasLength(1));
    final component = collection.components[0];
    expect(
      component.screenshots,
      equals([
        AppstreamScreenshot(
          images: [
            AppstreamImage(
              type: AppstreamImageType.source,
              url: 'https://example.com/screenshot1.jpg',
            ),
          ],
        ),
        AppstreamScreenshot(
          images: [
            AppstreamImage(
              type: AppstreamImageType.source,
              url: 'https://example.com/screenshot2.jpg',
            ),
          ],
          isDefault: true,
        ),
      ]),
    );
  });

  test('collection - releases - yaml', () async {
    final collection = AppstreamCollection.fromYaml("""---
File: DEP-11
Version: '0.12'
Origin: ubuntu-hirsute-main
---
Type: console-application
ID: com.example.Hello
Package: hello
Name:
  C: Hello World
Summary:
  C: A simple example application
Releases:
- version: '1.2'
  date: 2014-04-12
  urgency: high
  description:
    C: This stable release fixes bugs.
  url:
    details: https://example.com/releases/version-1.2.html
  issues:
  - id: '#123'
    url: https://github.com/example/example/issues/123
  - id: CVE-2019-123456
    type: cve
- version: '1.1'
  type: development
  date: 2013-10-20
- version: 1.0
  unix-timestamp: 1345939200
- unix-timestamp: 1234567890
- version: '0.9'
  type: snapshot
  date: 2012-01-15
""");
    expect(collection.components, hasLength(1));
    final component = collection.components[0];
    expect(
      component.releases,
      equals([
        AppstreamRelease(
          version: '1.2',
          date: DateTime(2014, 4, 12),
          urgency: AppstreamReleaseUrgency.high,
          description: {'C': 'This stable release fixes bugs.'},
          url: 'https://example.com/releases/version-1.2.html',
          issues: [
            AppstreamIssue(
              '#123',
              url: 'https://github.com/example/example/issues/123',
            ),
            AppstreamIssue('CVE-2019-123456', type: AppstreamIssueType.cve),
          ],
        ),
        AppstreamRelease(
          version: '1.1',
          type: AppstreamReleaseType.development,
          date: DateTime(2013, 10, 20),
        ),
        AppstreamRelease(version: '1.0', date: DateTime.utc(2012, 8, 26)),
        AppstreamRelease(date: DateTime.utc(2009, 2, 13, 23, 31, 30)),
        AppstreamRelease(
          version: '0.9',
          type: AppstreamReleaseType.snapshot,
          date: DateTime(2012, 1, 15),
        ),
      ]),
    );
  });

  test('collection - provides - yaml', () async {
    final collection = AppstreamCollection.fromYaml("""---
File: DEP-11
Version: '0.12'
Origin: ubuntu-hirsute-main
---
Type: console-application
ID: com.example.Hello
Package: hello
Name:
  C: Hello World
Summary:
  C: A simple example application
Provides:
  mediatypes:
  - text/html
  - image/png
  libraries:
  - libhello.so.1
  binaries:
  - hello
  fonts:
  - name: Hello
  modaliases:
  - usb:*
  firmware:
  - type: runtime
    file: hello.fw
  python2:
  - modhello
  python3:
  - modhello3
  dbus:
  - type: system
    service: com.example.Service
  ids:
  - com.example.SimpleHello
""");
    expect(collection.components, hasLength(1));
    final component = collection.components[0];
    expect(
      component.provides,
      equals([
        AppstreamProvidesMediatype('text/html'),
        AppstreamProvidesMediatype('image/png'),
        AppstreamProvidesLibrary('libhello.so.1'),
        AppstreamProvidesBinary('hello'),
        AppstreamProvidesFont('Hello'),
        AppstreamProvidesModalias('usb:*'),
        AppstreamProvidesFirmware(AppstreamFirmwareType.runtime, 'hello.fw'),
        AppstreamProvidesPython2('modhello'),
        AppstreamProvidesPython3('modhello3'),
        AppstreamProvidesDBus(
          AppstreamDBusType.system,
          'com.example.Service',
        ),
        AppstreamProvidesId('com.example.SimpleHello'),
      ]),
    );
  });

  test('collection - languages - yaml', () async {
    final collection = AppstreamCollection.fromYaml("""---
File: DEP-11
Version: '0.12'
Origin: ubuntu-hirsute-main
---
Type: console-application
ID: com.example.Hello
Package: hello
Name:
  C: Hello World
Summary:
  C: A simple example application
Languages:
  - locale: en
  - locale: de
    percentage: 42
""");
    expect(collection.components, hasLength(1));
    final component = collection.components[0];
    expect(
      component.languages,
      equals([
        AppstreamLanguage('en'),
        AppstreamLanguage('de', percentage: 42),
      ]),
    );
  });

  test('collection - content-rating - yaml', () async {
    final collection = AppstreamCollection.fromYaml("""---
File: DEP-11
Version: '0.12'
Origin: ubuntu-hirsute-main
---
Type: console-application
ID: com.example.Hello
Package: hello
Name:
  C: Hello World
Summary:
  C: A simple example application
ContentRating:
  oars-1.0:
    drugs-alcohol: moderate
    language-humor: mild
""");
    expect(collection.components, hasLength(1));
    final component = collection.components[0];
    expect(
      component.contentRatings,
      equals({
        'oars-1.0': {
          'drugs-alcohol': AppstreamContentRating.moderate,
          'language-humor': AppstreamContentRating.mild,
        },
      }),
    );
  });

  test('collection - bundles - yaml', () async {
    final collection = AppstreamCollection.fromYaml("""---
File: DEP-11
Version: '0.12'
Origin: ubuntu-hirsute-main
---
Type: console-application
ID: com.example.Hello
Package: hello
Name:
  C: Hello World
Summary:
  C: A simple example application
Bundles:
  - type: limba
    id: foobar-1.0.2
""");
    expect(collection.components, hasLength(1));
    final component = collection.components[0];
    expect(
      component.bundles,
      equals([
        AppstreamBundle('foobar-1.0.2', type: AppstreamBundleType.limba),
      ]),
    );
  });

  test('collection - custom - yaml', () async {
    final collection = AppstreamCollection.fromYaml("""---
File: DEP-11
Version: '0.12'
Origin: ubuntu-hirsute-main
---
Type: console-application
ID: com.example.Hello
Package: hello
Name:
  C: Hello World
Summary:
  C: A simple example application
Custom:
  - MyCorp::app_color: '#FF0000'
  - MyCorp::special_id: 284fd262-6870-42a6-89a4-b189d3109e3e
""");
    expect(collection.components, hasLength(1));
    final component = collection.components[0];
    expect(
      component.custom,
      equals([
        {'MyCorp::app_color': '#FF0000'},
        {'MyCorp::special_id': '284fd262-6870-42a6-89a4-b189d3109e3e'},
      ]),
    );
  });

  test('collection - locales - yaml', () async {
    const yaml = """---
File: DEP-11
Version: '0.12'
Origin: ubuntu-hirsute-main
---
Type: desktop-application
ID: com.example.Hello
Package: hello
Name:
  C: Hello
  de_DE: Hallo
  fr: Bonjour
Summary:
  C: Says hello
  de_DE: Sagt hallo
  fr: Dit bonjour
Description:
  C: <p>Greets the world.</p>
  de_DE: <p>Grüßt die Welt.</p>
  fr: <p>Salue le monde.</p>
DeveloperName:
  C: The Developer
  de_DE: Der Entwickler
  fr: Le développeur
Keywords:
  C:
    - greeting
  de_DE:
    - Gruß
  fr:
    - salutation
Screenshots:
- default: true
  caption:
    C: Main window
    de_DE: Hauptfenster
    fr: Fenêtre principale
  source-image:
    url: https://example.com/screenshot.png
Releases:
- version: '1.0'
  date: 2014-04-12
  description:
    C: <p>First release.</p>
    de_DE: <p>Erste Version.</p>
    fr: <p>Première version.</p>
""";

    final unfiltered = AppstreamCollection.fromYaml(yaml).components.single;
    expect(
      unfiltered.name,
      equals({'C': 'Hello', 'de_DE': 'Hallo', 'fr': 'Bonjour'}),
    );
    expect(
      unfiltered.summary,
      equals({'C': 'Says hello', 'de_DE': 'Sagt hallo', 'fr': 'Dit bonjour'}),
    );
    expect(
      unfiltered.description,
      equals({
        'C': '<p>Greets the world.</p>',
        'de_DE': '<p>Grüßt die Welt.</p>',
        'fr': '<p>Salue le monde.</p>',
      }),
    );
    expect(
      unfiltered.developerName,
      equals({
        'C': 'The Developer',
        'de_DE': 'Der Entwickler',
        'fr': 'Le développeur',
      }),
    );
    expect(
      unfiltered.keywords,
      equals({
        'C': ['greeting'],
        'de_DE': ['Gruß'],
        'fr': ['salutation'],
      }),
    );
    expect(
      unfiltered.screenshots.single.caption,
      equals({
        'C': 'Main window',
        'de_DE': 'Hauptfenster',
        'fr': 'Fenêtre principale',
      }),
    );
    expect(
      unfiltered.releases.single.description,
      equals({
        'C': '<p>First release.</p>',
        'de_DE': '<p>Erste Version.</p>',
        'fr': '<p>Première version.</p>',
      }),
    );

    final filtered = AppstreamCollection.fromYaml(yaml, locales: ['de_DE'])
        .components
        .single;
    expect(filtered.name, equals({'C': 'Hello', 'de_DE': 'Hallo'}));
    expect(
      filtered.summary,
      equals({'C': 'Says hello', 'de_DE': 'Sagt hallo'}),
    );
    expect(
      filtered.description,
      equals({
        'C': '<p>Greets the world.</p>',
        'de_DE': '<p>Grüßt die Welt.</p>',
      }),
    );
    expect(
      filtered.developerName,
      equals({'C': 'The Developer', 'de_DE': 'Der Entwickler'}),
    );
    expect(
      filtered.keywords,
      equals({
        'C': ['greeting'],
        'de_DE': ['Gruß'],
      }),
    );
    expect(
      filtered.screenshots.single.caption,
      equals({'C': 'Main window', 'de_DE': 'Hauptfenster'}),
    );
    expect(
      filtered.releases.single.description,
      equals({'C': '<p>First release.</p>', 'de_DE': '<p>Erste Version.</p>'}),
    );

    final cOnly =
        AppstreamCollection.fromYaml(yaml, locales: []).components.single;
    expect(cOnly.name, equals({'C': 'Hello'}));
    expect(cOnly.summary, equals({'C': 'Says hello'}));
    expect(cOnly.description, equals({'C': '<p>Greets the world.</p>'}));
    expect(cOnly.developerName, equals({'C': 'The Developer'}));
    expect(
      cOnly.keywords,
      equals({
        'C': ['greeting'],
      }),
    );
    expect(cOnly.screenshots.single.caption, equals({'C': 'Main window'}));
    expect(
      cOnly.releases.single.description,
      equals({'C': '<p>First release.</p>'}),
    );
  });

  test('collection - from lines, skipping invalid and empty documents - yaml',
      () async {
    const yaml = """---
File: DEP-11
Version: '0.12'
Origin: ubuntu-hirsute-main
---
Type: console-application
ID: com.example.Hello
Package: hello
Name:
  C: Hello World
Summary:
  C: A simple example application
---
Type: console-application
ID: com.example.Broken
Package: broken
Name:
  C: Broken
Summary:
  C: A component with a duplicate mapping key
Summary:
  C: The duplicate
---
---
Type: console-application
ID: com.example.Goodbye
Package: goodbye
Name:
  C: Goodbye World
Summary:
  C: Another simple example application
""";

    final fromLines = AppstreamCollection.fromYamlLines(yaml.split('\n'));
    expect(fromLines.version, equals('0.12'));
    expect(fromLines.origin, equals('ubuntu-hirsute-main'));
    expect(
      fromLines.components.map((c) => c.id),
      equals(['com.example.Hello', 'com.example.Goodbye']),
    );
    expect(
      fromLines.components.map((c) => c.name),
      equals([
        {'C': 'Hello World'},
        {'C': 'Goodbye World'},
      ]),
    );
    expect(
      fromLines.components.map((c) => c.summary),
      equals([
        {'C': 'A simple example application'},
        {'C': 'Another simple example application'},
      ]),
    );

    final fromString = AppstreamCollection.fromYaml(yaml);
    expect(
      fromString.components.map((c) => c.id),
      equals(fromLines.components.map((c) => c.id)),
    );
    expect(
      fromString.components.map((c) => c.name),
      equals(fromLines.components.map((c) => c.name)),
    );
    expect(
      fromString.components.map((c) => c.summary),
      equals(fromLines.components.map((c) => c.summary)),
    );
  });

  test(
    'pool - unparseable catalog reports an error instead of hanging',
    () async {
      final tempDir = await Directory.systemTemp.createTemp('appstream_pool');
      addTearDown(() => tempDir.delete(recursive: true));

      final yamlDir = Directory('${tempDir.path}/swcatalog/yaml');
      await yamlDir.create(recursive: true);
      await File('${yamlDir.path}/broken.yml').writeAsString("""---
File: DEP-11
Version: '0.12'
Origin: test
---
Type: console-application
ID: com.example.Hello
Package: hello
Name:
  C: Hello World
Summary:
  C: A simple example application
Releases:
- version: '1.0'
  type: definitely-not-a-release-type
""");

      // The parse runs in a spawned isolate. Before the error port was wired up,
      // the isolate died without ever sending a result and `load()` waited on it
      // forever, so this has to fail loudly rather than time out.
      await expectLater(
        AppstreamPool(catalogDirPrefixes: [tempDir.path]).load(),
        throwsA(isA<AppstreamCollectionLoadException>()),
      );
    },
    timeout: const Timeout(Duration(seconds: 30)),
  );

  test(
    'pool - a catalog that fails right away is reported by load() alone',
    () async {
      final tempDir = await Directory.systemTemp.createTemp('appstream_pool');
      addTearDown(() => tempDir.delete(recursive: true));

      final yamlDir = Directory('${tempDir.path}/first/swcatalog/yaml');
      await yamlDir.create(recursive: true);
      await File('${yamlDir.path}/broken.yml').writeAsString("""---
File: DEP-11
Version: '0.12'
Origin: test
---
Type: console-application
ID: com.example.Hello
Package: hello
Name:
  C: Hello World
Summary:
  C: A simple example application
Releases:
- version: '1.0'
  type: definitely-not-a-release-type
""");

      // Listing the directories after the broken catalog takes longer than it
      // needs to fail. A loader started before that would fail with nobody
      // listening yet, and the error would also surface as uncaught.
      final prefixes = [
        '${tempDir.path}/first',
        for (var i = 0; i < 400; i++) '${tempDir.path}/missing$i',
      ];
      final uncaught = <Object>[];
      await runZonedGuarded(
        () async {
          await expectLater(
            AppstreamPool(catalogDirPrefixes: prefixes).load(),
            throwsA(isA<AppstreamCollectionLoadException>()),
          );
          // Gives an error that nobody listened to time to reach the zone.
          await Future<void>.delayed(const Duration(milliseconds: 300));
        },
        (error, stack) => uncaught.add(error),
      );
      expect(uncaught, isEmpty);
    },
    timeout: const Timeout(Duration(seconds: 30)),
  );

  test('pool - gzip-compressed yaml catalog keeps only the requested locales',
      () async {
    final tempDir = await Directory.systemTemp.createTemp('appstream_pool');
    addTearDown(() => tempDir.delete(recursive: true));

    // Big enough that the pool reads and decompresses it in several chunks.
    const componentCount = 4000;
    final yaml = StringBuffer("""---
File: DEP-11
Version: '0.12'
Origin: test
""");
    for (var i = 0; i < componentCount; ++i) {
      yaml.write('''---
Type: desktop-application
ID: com.example.App$i
Package: app$i
Name:
  C: App $i
  de_DE: Anwendung $i
  fr: Application $i
Summary:
  C: Greets you $i times
  de_DE: Grüßt Sie $i Mal
  fr: Vous salue $i fois
''');
    }
    final yamlDir = Directory('${tempDir.path}/swcatalog/yaml');
    await yamlDir.create(recursive: true);
    final compressed = File('${yamlDir.path}/test.yml.gz');
    await compressed.writeAsBytes(gzip.encode(utf8.encode(yaml.toString())));
    expect(compressed.lengthSync(), greaterThan(64 * 1024));

    final pool = AppstreamPool(
      catalogDirPrefixes: [tempDir.path],
      locales: ['de_DE'],
    );
    await pool.load();

    expect(
      pool.components.map((c) => c.id),
      equals([for (var i = 0; i < componentCount; ++i) 'com.example.App$i']),
    );
    expect(
      pool.components.map((c) => c.name),
      equals([
        for (var i = 0; i < componentCount; ++i)
          {'C': 'App $i', 'de_DE': 'Anwendung $i'},
      ]),
    );
    expect(
      pool.components.map((c) => c.summary),
      equals([
        for (var i = 0; i < componentCount; ++i)
          {'C': 'Greets you $i times', 'de_DE': 'Grüßt Sie $i Mal'},
      ]),
    );
  });

  test('pool - plain yaml catalog with CRLF line endings', () async {
    final tempDir = await Directory.systemTemp.createTemp('appstream_pool');
    addTearDown(() => tempDir.delete(recursive: true));

    // The summary spans three 64 KiB reads; the first ends inside a character.
    final summary = '€' * 50000;
    final yaml = '---\r\n'
        'File: DEP-11\r\n'
        "Version: '0.12'\r\n"
        'Origin: test\r\n'
        '---\r\n'
        'Type: desktop-application\r\n'
        'ID: com.example.Big\r\n'
        'Package: big\r\n'
        'Name:\r\n'
        '  C: Big\r\n'
        'Summary:\r\n'
        '  C: $summary\r\n'
        '---\r\n'
        'Type: desktop-application\r\n'
        'ID: com.example.Small\r\n'
        'Package: small\r\n'
        'Name:\r\n'
        '  C: Small\r\n'
        'Summary:\r\n'
        '  C: A short summary\r\n';
    final yamlDir = Directory('${tempDir.path}/swcatalog/yaml');
    await yamlDir.create(recursive: true);
    await File('${yamlDir.path}/test.yml').writeAsString(yaml);

    final pool = AppstreamPool(catalogDirPrefixes: [tempDir.path]);
    await pool.load();

    expect(
      pool.components.map((component) => component.id),
      equals(['com.example.Big', 'com.example.Small']),
    );
    expect(pool.components.first.summary, equals({'C': summary}));
    expect(pool.components.last.summary, equals({'C': 'A short summary'}));
  });

  test('pool - yaml catalog without a final newline loads completely',
      () async {
    final tempDir = await Directory.systemTemp.createTemp('appstream_pool');
    addTearDown(() => tempDir.delete(recursive: true));

    final yamlDir = Directory('${tempDir.path}/swcatalog/yaml');
    await yamlDir.create(recursive: true);
    await File('${yamlDir.path}/test.yml').writeAsString("""---
File: DEP-11
Version: '0.12'
Origin: test
---
Type: console-application
ID: com.example.Hello
Package: hello
Name:
  C: Hello World
Summary:
  C: A simple example application""");

    final pool = AppstreamPool(catalogDirPrefixes: [tempDir.path]);
    await pool.load();

    final component = pool.components.single;
    expect(component.id, equals('com.example.Hello'));
    expect(component.summary, equals({'C': 'A simple example application'}));
  });

  // Each file in [catalogs] (name -> component IDs) becomes a YAML catalog.
  Future<AppstreamPool> poolOf(Map<String, List<String>> catalogs) async {
    final tempDir = await Directory.systemTemp.createTemp('appstream_pool');
    addTearDown(() => tempDir.delete(recursive: true));
    final yamlDir = Directory('${tempDir.path}/swcatalog/yaml');
    await yamlDir.create(recursive: true);
    for (final catalog in catalogs.entries) {
      final yaml = StringBuffer('---\nFile: DEP-11\nVersion: "0.12"\n')
        ..write('Origin: test\n');
      for (final id in catalog.value) {
        yaml.write('---\nType: console-application\nID: $id\nPackage: p-$id\n'
            'Name:\n  C: $id\nSummary:\n  C: Summary of $id\n');
      }
      await File('${yamlDir.path}/${catalog.key}.yml')
          .writeAsString(yaml.toString());
    }
    return AppstreamPool(catalogDirPrefixes: [tempDir.path]);
  }

  test('pool - components read by index match those read in a pass', () async {
    final pool = await poolOf({
      'a': ['a1', 'a2'],
      'b': ['b1'],
      'c': [],
      'd': ['d1', 'd2', 'd3'],
    });
    await pool.load();

    final scanned = [for (final component in pool.components) component.id];
    expect(scanned, hasLength(6));
    expect(scanned.toSet(), equals({'a1', 'a2', 'b1', 'd1', 'd2', 'd3'}));
    expect(pool.components, hasLength(6));
    expect(
      [for (var i = 0; i < 6; i++) pool.components[i].id],
      equals(scanned),
    );
    expect(() => pool.components[6], throwsRangeError);
    expect(() => pool.components[-1], throwsRangeError);
  });

  test('pool - a component read by index is the same object each time',
      () async {
    final pool = await poolOf({
      'a': ['a1', 'a2'],
    });
    await pool.load();

    expect(identical(pool.components[1], pool.components[1]), isTrue);
  });

  test('pool - components cannot be changed', () async {
    final pool = await poolOf({
      'a': ['a1', 'a2'],
    });
    await pool.load();

    expect(() => pool.components.removeLast(), throwsUnsupportedError);
    expect(() => pool.components.clear(), throwsUnsupportedError);
    expect(
      () => pool.components[0] = pool.components[1],
      throwsUnsupportedError,
    );
    expect(pool.components, hasLength(2));
  });

  test('pool - loading again replaces the components', () async {
    final pool = await poolOf({
      'a': ['a1', 'a2'],
    });
    expect(pool.components, isEmpty);
    await pool.load();
    await pool.load();

    expect([for (final c in pool.components) c.id], equals(['a1', 'a2']));
  });

  // One component with every detail and the data beside them, in both formats.
  const omitXml = '''<components version="0.14" origin="test">
  <component type="desktop-application">
    <id>com.example.Hello</id>
    <pkgname>hello</pkgname>
    <name>Hello World</name>
    <summary>A simple example application</summary>
    <icon type="stock">hello</icon>
    <icon type="cached" width="64" height="64">hello_64.png</icon>
    <screenshots>
      <screenshot type="default">
        <caption>The main window</caption>
        <image type="source" width="1024" height="768">https://example.com/hello.png</image>
        <image type="thumbnail" width="224" height="168">https://example.com/hello-small.png</image>
      </screenshot>
    </screenshots>
    <releases>
      <release version="1.2" timestamp="1700000000" urgency="high">
        <description><p>Fixes things.</p></description>
        <url>https://example.com/releases/1.2</url>
        <issues>
          <issue url="https://example.com/issues/1">HELLO-1</issue>
        </issues>
      </release>
      <release version="1.1" type="development" date="2023-01-02"/>
    </releases>
    <languages>
      <lang percentage="96">de</lang>
    </languages>
    <content_rating type="oars-1.1">
      <content_attribute id="violence-cartoon">mild</content_attribute>
    </content_rating>
  </component>
</components>
''';
  const omitYaml = """---
File: DEP-11
Version: '0.14'
Origin: test
---
Type: desktop-application
ID: com.example.Hello
Package: hello
Name:
  C: Hello World
Summary:
  C: A simple example application
Icon:
  stock: hello
  cached:
  - name: hello_64.png
    width: 64
    height: 64
Screenshots:
- default: true
  caption:
    C: The main window
  thumbnails:
  - url: https://example.com/hello-small.png
    width: 224
    height: 168
  source-image:
    url: https://example.com/hello.png
    width: 1024
    height: 768
Releases:
- version: '1.2'
  unix-timestamp: 1700000000
  urgency: high
  description:
    C: <p>Fixes things.</p>
  url:
    details: https://example.com/releases/1.2
  issues:
  - id: HELLO-1
    url: https://example.com/issues/1
- version: '1.1'
  type: development
  date: 2023-01-02
Languages:
- locale: de
  percentage: 96
ContentRating:
  oars-1.1:
    violence-cartoon: mild
""";
  final omitParsers =
      <String, AppstreamCollection Function(Iterable<AppstreamDetail> omit)>{
    'xml': (omit) => AppstreamCollection.fromXml(omitXml, omit: omit),
    'yaml': (omit) => AppstreamCollection.fromYaml(omitYaml, omit: omit),
  };

  final omitCases = [
    _OmitCase(
      AppstreamDetail.cachedIcons,
      (component) => component.icons.whereType<AppstreamCachedIcon>().toList(),
      [AppstreamCachedIcon('hello_64.png', width: 64, height: 64)],
    ),
    _OmitCase(
      AppstreamDetail.contentRatings,
      (component) => component.contentRatings,
      {
        'oars-1.1': {'violence-cartoon': AppstreamContentRating.mild},
      },
    ),
    _OmitCase(
      AppstreamDetail.languages,
      (component) => component.languages,
      [AppstreamLanguage('de', percentage: 96)],
    ),
    _OmitCase(
      AppstreamDetail.releaseNotes,
      (component) => [
        for (final release in component.releases) ...[
          if (release.description.isNotEmpty) release.description,
          if (release.url != null) release.url,
          ...release.issues,
        ],
      ],
      [
        {'C': '<p>Fixes things.</p>'},
        'https://example.com/releases/1.2',
        AppstreamIssue('HELLO-1', url: 'https://example.com/issues/1'),
      ],
    ),
    _OmitCase(
      AppstreamDetail.screenshotCaptions,
      (component) => [
        for (final screenshot in component.screenshots)
          if (screenshot.caption.isNotEmpty) screenshot.caption,
      ],
      [
        {'C': 'The main window'},
      ],
    ),
    _OmitCase(
      AppstreamDetail.screenshotThumbnails,
      (component) => [
        for (final screenshot in component.screenshots)
          ...screenshot.images
              .where((image) => image.type == AppstreamImageType.thumbnail),
      ],
      [
        AppstreamImage(
          type: AppstreamImageType.thumbnail,
          url: 'https://example.com/hello-small.png',
          width: 224,
          height: 168,
        ),
      ],
    ),
  ];

  // The data next to the details, which omitting them must leave in place.
  List<Object> readKeptData(AppstreamComponent component) => [
        ...component.icons.whereType<AppstreamStockIcon>(),
        for (final screenshot in component.screenshots)
          AppstreamScreenshot(
            isDefault: screenshot.isDefault,
            images: screenshot.images
                .where((image) => image.type == AppstreamImageType.source)
                .toList(),
          ),
        for (final release in component.releases)
          AppstreamRelease(
            version: release.version,
            date: release.date,
            type: release.type,
            urgency: release.urgency,
          ),
      ];
  final keptData = [
    AppstreamStockIcon('hello'),
    AppstreamScreenshot(
      isDefault: true,
      images: [
        AppstreamImage(
          type: AppstreamImageType.source,
          url: 'https://example.com/hello.png',
          width: 1024,
          height: 768,
        ),
      ],
    ),
    AppstreamRelease(
      version: '1.2',
      date: DateTime.utc(2023, 11, 14, 22, 13, 20),
      urgency: AppstreamReleaseUrgency.high,
    ),
    AppstreamRelease(
      version: '1.1',
      date: DateTime(2023, 1, 2),
      type: AppstreamReleaseType.development,
    ),
  ];

  test('collection - omit cases cover every detail', () {
    expect(
      omitCases.map((omitCase) => omitCase.detail),
      unorderedEquals(AppstreamDetail.values),
    );
  });

  for (final parser in omitParsers.entries) {
    for (final omitCase in omitCases) {
      test('collection - omit ${omitCase.detail.name} - ${parser.key}', () {
        final kept = parser.value(const {}).components.single;
        expect(omitCase.read(kept), equals(omitCase.present));

        final component = parser.value({omitCase.detail}).components.single;
        expect(omitCase.read(component), isEmpty);
        expect(readKeptData(component), equals(keptData));
        for (final other in omitCases.where((other) => other != omitCase)) {
          expect(
            other.read(component),
            equals(other.present),
            reason: '${other.detail.name} is not omitted',
          );
        }
      });
    }
  }

  test('pool - omit leaves details out of xml and yaml catalogs', () async {
    final tempDir = await Directory.systemTemp.createTemp('appstream_pool');
    addTearDown(() => tempDir.delete(recursive: true));

    final yamlDir = Directory('${tempDir.path}/swcatalog/yaml');
    await yamlDir.create(recursive: true);
    await File('${tempDir.path}/swcatalog/test.xml').writeAsString(omitXml);
    await File('${yamlDir.path}/test.yml').writeAsString(omitYaml);

    final pool = AppstreamPool(
      catalogDirPrefixes: [tempDir.path],
      omit: AppstreamDetail.values,
    );
    await pool.load();

    expect(pool.components, hasLength(2));
    for (final component in pool.components) {
      for (final omitCase in omitCases) {
        expect(
          omitCase.read(component),
          isEmpty,
          reason: '${omitCase.detail.name} is omitted',
        );
      }
      expect(readKeptData(component), equals(keptData));
    }
  });
}

class _OmitCase {
  const _OmitCase(this.detail, this.read, this.present);

  final AppstreamDetail detail;

  /// Reads the metadata [detail] covers, which is empty when it is omitted.
  final Object Function(AppstreamComponent component) read;

  /// What [read] returns when [detail] is kept.
  final Object present;
}
