import 'package:appstream/appstream.dart';
import 'package:test/test.dart';

void main() {
  test('collection - empty xml', () async {
    expect(() => AppstreamCollection.fromXml(''), throwsFormatException);
  });

  test('collection - invalid xml', () async {
    expect(() => AppstreamCollection.fromXml('<foo></foo>'),
        throwsFormatException);
  });

  test('collection - empty - xml', () async {
    var collection = AppstreamCollection.fromXml(
        '<components version="0.12" origin="ubuntu-hirsute-main"/>');
    expect(collection.version, equals('0.12'));
    expect(collection.origin, equals('ubuntu-hirsute-main'));
    expect(collection.architecture, isNull);
    expect(collection.priority, isNull);
    expect(collection.components, isEmpty);
  });

  test('collection - architecture - xml', () async {
    var collection = AppstreamCollection.fromXml(
        '<components version="0.12" origin="ubuntu-hirsute-main" architecture="arm64"/>');
    expect(collection.architecture, equals('arm64'));
  });

  test('collection - single - xml', () async {
    var collection = AppstreamCollection.fromXml(
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
    var component = collection.components[0];
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
    var collection = AppstreamCollection.fromXml(
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
    var component = collection.components[0];
    expect(component.description,
        equals({'C': '<p>The <b>best</b> thing since sliced bread</p>'}));
    expect(component.developerName, equals({'C': 'The Developer'}));
    expect(component.projectLicense, equals('GPL-3'));
    expect(component.projectGroup, equals('GNOME'));
    expect(component.compulsoryForDesktops, equals(['GNOME', 'KDE']));
  });

  test('collection - icons - xml', () async {
    var collection = AppstreamCollection.fromXml(
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
    var component = collection.components[0];
    expect(component.icons, hasLength(4));
    expect(
        component.icons,
        equals([
          AppstreamStockIcon('stock-name'),
          AppstreamCachedIcon('icon.png', width: 8, height: 16),
          AppstreamLocalIcon('/path/to/icon.png', width: 32, height: 48),
          AppstreamRemoteIcon('https://example.com/icon.png',
              width: 64, height: 128)
        ]));
  });

  test('collection - urls - xml', () async {
    var collection = AppstreamCollection.fromXml(
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
    var component = collection.components[0];
    expect(
        component.urls,
        equals([
          AppstreamUrl('https://example.com', type: AppstreamUrlType.homepage),
          AppstreamUrl('https://example.com/help', type: AppstreamUrlType.help),
          AppstreamUrl('', type: AppstreamUrlType.contact)
        ]));
  });

  test('collection - launchables - xml', () async {
    var collection = AppstreamCollection.fromXml(
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
    var component = collection.components[0];
    expect(
        component.launchables,
        equals([
          AppstreamLaunchableDesktopId('com.example.Hello1'),
          AppstreamLaunchableDesktopId('com.example.Hello2'),
          AppstreamLaunchableUrl('https://example.com/launch')
        ]));
  });

  test('collection - categories - xml', () async {
    var collection = AppstreamCollection.fromXml(
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
    var component = collection.components[0];
    expect(component.categories, equals(['Game', 'ArcadeGame']));
  });

  test('collection - keywords - xml', () async {
    var collection = AppstreamCollection.fromXml(
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
    var component = collection.components[0];
    expect(
        component.keywords,
        equals({
          'C': ['Hello', 'Welcome'],
          'de_DE': ['Hallo', 'Wilkommen']
        }));
  });

  test('collection - screenshot - xml', () async {
    var collection = AppstreamCollection.fromXml(
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
    var component = collection.components[0];
    expect(
        component.screenshots,
        equals([
          AppstreamScreenshot(images: [
            AppstreamImage(
                type: AppstreamImageType.thumbnail,
                url: 'https://example.com/thumbnail-big.jpg',
                width: 512,
                height: 384),
            AppstreamImage(
                type: AppstreamImageType.thumbnail,
                url: 'https://example.com/thumbnail-small.jpg',
                width: 256,
                height: 192,
                lang: 'en_NZ'),
            AppstreamImage(
                type: AppstreamImageType.source,
                url: 'https://example.com/screenshot.jpg',
                width: 1024,
                height: 768)
          ], caption: {
            'C': 'A screenshot'
          })
        ]));
  });

  test('collection - screenshots - xml', () async {
    var collection = AppstreamCollection.fromXml(
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
    var component = collection.components[0];
    expect(
        component.screenshots,
        equals([
          AppstreamScreenshot(images: [
            AppstreamImage(
              type: AppstreamImageType.source,
              url: 'https://example.com/screenshot1.jpg',
            )
          ]),
          AppstreamScreenshot(images: [
            AppstreamImage(
                type: AppstreamImageType.source,
                url: 'https://example.com/screenshot2.jpg')
          ], isDefault: true)
        ]));
  });

  test('collection - releases - xml', () async {
    var collection = AppstreamCollection.fromXml(
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
    </releases>
  </component>
</components>
''');
    expect(collection.components, hasLength(1));
    var component = collection.components[0];
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
                AppstreamIssue('#123',
                    url: 'https://github.com/example/example/issues/123'),
                AppstreamIssue('CVE-2019-123456', type: AppstreamIssueType.cve)
              ]),
          AppstreamRelease(
              version: '1.1',
              type: AppstreamReleaseType.development,
              date: DateTime(2013, 10, 20)),
          AppstreamRelease(version: '1.0', date: DateTime.utc(2012, 8, 26))
        ]));
  });

  test('collection - provides - xml', () async {
    var collection = AppstreamCollection.fromXml(
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
    var component = collection.components[0];
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
              AppstreamDBusType.system, 'com.example.Service'),
          AppstreamProvidesId('com.example.SimpleHello')
        ]));
  });

  test('collection - languages - xml', () async {
    var collection = AppstreamCollection.fromXml(
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
    var component = collection.components[0];
    expect(
        component.languages,
        equals([
          AppstreamLanguage('en'),
          AppstreamLanguage('de', percentage: 42)
        ]));
  });

  test('collection - content-rating - xml', () async {
    var collection = AppstreamCollection.fromXml(
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
    var component = collection.components[0];
    expect(
        component.contentRatings,
        equals({
          'oars-1.0': {
            'drugs-alcohol': AppstreamContentRating.moderate,
            'language-humor': AppstreamContentRating.mild
          }
        }));
  });

  test('collection - empty yaml', () async {
    expect(() => AppstreamCollection.fromYaml(''), throwsFormatException);
  });

  test('collection - invalid yaml', () async {
    expect(() => AppstreamCollection.fromYaml('---\nFile: NotTheRightThing\n'),
        throwsFormatException);
  });

  test('collection - yaml with duplicate mapping keys', () async {
    var collection = AppstreamCollection.fromYaml("""---
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
    var collection = AppstreamCollection.fromYaml("""---
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
    var collection = AppstreamCollection.fromYaml("""---
File: DEP-11
Version: '0.12'
Origin: ubuntu-hirsute-main
Architecture: arm64
""");
    expect(collection.architecture, equals('arm64'));
  });

  test('collection - priority - yaml', () async {
    var collection = AppstreamCollection.fromYaml("""---
File: DEP-11
Version: '0.12'
Origin: ubuntu-hirsute-main
Priority: 42
""");
    expect(collection.priority, equals(42));
  });

  test('collection - single - yaml', () async {
    var collection = AppstreamCollection.fromYaml("""---
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
    var component = collection.components[0];
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
    var collection = AppstreamCollection.fromYaml("""---
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
    var component = collection.components[0];
    expect(component.description,
        equals({'C': '<p>The <b>best</b> thing since sliced bread</p>'}));
    expect(component.developerName, equals({'C': 'The Developer'}));
    expect(component.projectLicense, equals('GPL-3'));
    expect(component.projectGroup, equals('GNOME'));
    expect(component.compulsoryForDesktops, equals(['GNOME', 'KDE']));
  });

  test('collection - icons - yaml', () async {
    var collection = AppstreamCollection.fromYaml("""---
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
    var component = collection.components[0];
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
          AppstreamRemoteIcon('https://example.com/icon.png',
              width: 64, height: 128),
          AppstreamRemoteIcon('https://example.com/images/icon-big.png',
              width: 256, height: 256)
        ]));
  });

  test('collection - urls - yaml', () async {
    var collection = AppstreamCollection.fromYaml("""---
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
    var component = collection.components[0];
    expect(
        component.urls,
        equals([
          AppstreamUrl('https://example.com', type: AppstreamUrlType.homepage),
          AppstreamUrl('https://example.com/help', type: AppstreamUrlType.help),
          AppstreamUrl('', type: AppstreamUrlType.contact)
        ]));
  });

  test('collection - launchables - yaml', () async {
    var collection = AppstreamCollection.fromYaml("""---
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
    var component = collection.components[0];
    expect(
        component.launchables,
        equals([
          AppstreamLaunchableDesktopId('com.example.Hello1'),
          AppstreamLaunchableDesktopId('com.example.Hello2'),
          AppstreamLaunchableUrl('https://example.com/launch')
        ]));
  });

  test('collection - categories - yaml', () async {
    var collection = AppstreamCollection.fromYaml("""---
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
    var component = collection.components[0];
    expect(component.categories, equals(['Game', 'ArcadeGame']));
  });

  test('collection - keywords - yaml', () async {
    var collection = AppstreamCollection.fromYaml("""---
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
    var component = collection.components[0];
    expect(
        component.keywords,
        equals({
          'C': ['Hello', 'Welcome'],
          'de_DE': ['Hallo', 'Wilkommen']
        }));
  });

  test('collection - keywords (null values) - yaml', () async {
    // Test for https://github.com/canonical/appstream.dart/issues/22
    var collection = AppstreamCollection.fromYaml("""---
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
    var component = collection.components[0];
    expect(
        component.keywords,
        equals({
          'C': ['Hello', 'Welcome'],
          'de_DE': ['Hallo', 'Wilkommen']
        }));
  });

  test('collection - screenshot - yaml', () async {
    var collection = AppstreamCollection.fromYaml("""---
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
    var component = collection.components[0];
    expect(
        component.screenshots,
        equals([
          AppstreamScreenshot(images: [
            AppstreamImage(
                type: AppstreamImageType.thumbnail,
                url: 'https://example.com/thumbnail-big.jpg',
                width: 512,
                height: 384),
            AppstreamImage(
                type: AppstreamImageType.thumbnail,
                url: 'https://example.com/images/thumbnail-small.jpg',
                width: 256,
                height: 192,
                lang: 'en_NZ'),
            AppstreamImage(
                type: AppstreamImageType.source,
                url: 'https://example.com/images/screenshot.jpg',
                width: 1024,
                height: 768)
          ], caption: {
            'C': 'A screenshot'
          })
        ]));
  });

  test('collection - screenshots - yaml', () async {
    var collection = AppstreamCollection.fromYaml("""---
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
    var component = collection.components[0];
    expect(
        component.screenshots,
        equals([
          AppstreamScreenshot(images: [
            AppstreamImage(
              type: AppstreamImageType.source,
              url: 'https://example.com/screenshot1.jpg',
            )
          ]),
          AppstreamScreenshot(images: [
            AppstreamImage(
                type: AppstreamImageType.source,
                url: 'https://example.com/screenshot2.jpg')
          ], isDefault: true)
        ]));
  });

  test('collection - releases - yaml', () async {
    var collection = AppstreamCollection.fromYaml("""---
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
""");
    expect(collection.components, hasLength(1));
    var component = collection.components[0];
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
                AppstreamIssue('#123',
                    url: 'https://github.com/example/example/issues/123'),
                AppstreamIssue('CVE-2019-123456', type: AppstreamIssueType.cve)
              ]),
          AppstreamRelease(
              version: '1.1',
              type: AppstreamReleaseType.development,
              date: DateTime(2013, 10, 20)),
          AppstreamRelease(version: '1.0', date: DateTime.utc(2012, 8, 26))
        ]));
  });

  test('collection - provides - yaml', () async {
    var collection = AppstreamCollection.fromYaml("""---
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
    var component = collection.components[0];
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
              AppstreamDBusType.system, 'com.example.Service'),
          AppstreamProvidesId('com.example.SimpleHello')
        ]));
  });

  test('collection - languages - yaml', () async {
    var collection = AppstreamCollection.fromYaml("""---
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
    var component = collection.components[0];
    expect(
        component.languages,
        equals([
          AppstreamLanguage('en'),
          AppstreamLanguage('de', percentage: 42)
        ]));
  });

  test('collection - content-rating - yaml', () async {
    var collection = AppstreamCollection.fromYaml("""---
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
    var component = collection.components[0];
    expect(
        component.contentRatings,
        equals({
          'oars-1.0': {
            'drugs-alcohol': AppstreamContentRating.moderate,
            'language-humor': AppstreamContentRating.mild
          }
        }));
  });
}
