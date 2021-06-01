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
        '<components><version>0.12</version><origin>ubuntu-hirsute-main</origin></components>');
    expect(collection.version, equals('0.12'));
    expect(collection.origin, equals('ubuntu-hirsute-main'));
    expect(collection.architecture, isNull);
    expect(collection.priority, isNull);
    expect(collection.components, isEmpty);
  });

  test('collection - single - xml', () async {
    var collection = AppstreamCollection.fromXml('''<components>
  <version>0.12</version>
  <origin>ubuntu-hirsute-main</origin>
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
    expect(component.icons, isEmpty);
    expect(component.urls, isEmpty);
    expect(component.screenshots, isEmpty);
  });

  test('collection - icons - xml', () async {
    var collection = AppstreamCollection.fromXml('''<components>
  <version>0.12</version>
  <origin>ubuntu-hirsute-main</origin>
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
    var collection = AppstreamCollection.fromXml('''<components>
  <version>0.12</version>
  <origin>ubuntu-hirsute-main</origin>
  <component type="console-application">
    <id>com.example.Hello</id>
    <pkgname>hello</pkgname>
    <name>Hello World</name>
    <summary>A simple example application</summary>
    <url type="homepage">https://example.com</url>
    <url type="help">https://example.com/help</url>
    <url type="contact">https://example.com/contact</url>
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
          AppstreamUrl('https://example.com/contact',
              type: AppstreamUrlType.contact)
        ]));
  });

  test('collection - screenshot - xml', () async {
    var collection = AppstreamCollection.fromXml('''<components>
  <version>0.12</version>
  <origin>ubuntu-hirsute-main</origin>
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
                lang: "en_NZ"),
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
    var collection = AppstreamCollection.fromXml('''<components>
  <version>0.12</version>
  <origin>ubuntu-hirsute-main</origin>
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

  test('collection - empty yaml', () async {
    expect(() => AppstreamCollection.fromYaml(''), throwsFormatException);
  });

  test('collection - invalid yaml', () async {
    expect(() => AppstreamCollection.fromYaml('---\nFile: NotTheRightThing\n'),
        throwsFormatException);
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
    expect(component.icons, isEmpty);
    expect(component.urls, isEmpty);
    expect(component.screenshots, isEmpty);
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
  contact: https://example.com/contact
""");
    expect(collection.components, hasLength(1));
    var component = collection.components[0];
    expect(
        component.urls,
        equals([
          AppstreamUrl('https://example.com', type: AppstreamUrlType.homepage),
          AppstreamUrl('https://example.com/help', type: AppstreamUrlType.help),
          AppstreamUrl('https://example.com/contact',
              type: AppstreamUrlType.contact)
        ]));
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
                lang: "en_NZ"),
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
}
