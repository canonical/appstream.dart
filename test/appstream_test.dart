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
    expect(component.type, equals('console-application'));
    expect(component.package, equals('hello'));
    expect(component.name, equals({'C': 'Hello World'}));
    expect(component.summary, equals({'C': 'A simple example application'}));
    expect(component.icons, isEmpty);
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
    <icon type="remote" width="64" height="128">http://example.com/icon.png</icon>
  </component>
</components>
''');
    expect(collection.components, hasLength(1));
    var component = collection.components[0];
    expect(component.icons, hasLength(4));
    expect(component.icons[0], isA<AppstreamStockIcon>());
    var stockIcon = component.icons[0] as AppstreamStockIcon;
    expect(stockIcon.name, equals('stock-name'));
    expect(component.icons[1], isA<AppstreamCachedIcon>());
    var cachedIcon = component.icons[1] as AppstreamCachedIcon;
    expect(cachedIcon.name, equals('icon.png'));
    expect(cachedIcon.width, equals(8));
    expect(cachedIcon.height, equals(16));
    expect(component.icons[2], isA<AppstreamLocalIcon>());
    var localIcon = component.icons[2] as AppstreamLocalIcon;
    expect(localIcon.filename, equals('/path/to/icon.png'));
    expect(localIcon.width, equals(32));
    expect(localIcon.height, equals(48));
    expect(component.icons[3], isA<AppstreamRemoteIcon>());
    var remoteIcon = component.icons[3] as AppstreamRemoteIcon;
    expect(remoteIcon.url, equals('http://example.com/icon.png'));
    expect(remoteIcon.width, equals(64));
    expect(remoteIcon.height, equals(128));
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
    expect(component.type, equals('console-application'));
    expect(component.package, equals('hello'));
    expect(component.name, equals({'C': 'Hello World'}));
    expect(component.summary, equals({'C': 'A simple example application'}));
    expect(component.icons, isEmpty);
  });

  test('collection - icons - yaml', () async {
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
  - url: http://example.com/icon.png
    width: 64
    height: 128
""");
    expect(collection.components, hasLength(1));
    var component = collection.components[0];
    expect(component.id, equals('com.example.Hello'));
    expect(component.type, equals('console-application'));
    expect(component.package, equals('hello'));
    expect(component.name, equals({'C': 'Hello World'}));
    expect(component.summary, equals({'C': 'A simple example application'}));
    expect(component.icons, hasLength(4));
    expect(component.icons[0], isA<AppstreamStockIcon>());
    var stockIcon = component.icons[0] as AppstreamStockIcon;
    expect(stockIcon.name, equals('stock-name'));
    expect(component.icons[1], isA<AppstreamCachedIcon>());
    var cachedIcon = component.icons[1] as AppstreamCachedIcon;
    expect(cachedIcon.name, equals('icon.png'));
    expect(cachedIcon.width, equals(8));
    expect(cachedIcon.height, equals(16));
    expect(component.icons[2], isA<AppstreamLocalIcon>());
    var localIcon = component.icons[2] as AppstreamLocalIcon;
    expect(localIcon.filename, equals('/path/to/icon.png'));
    expect(localIcon.width, equals(32));
    expect(localIcon.height, equals(48));
    expect(component.icons[3], isA<AppstreamRemoteIcon>());
    var remoteIcon = component.icons[3] as AppstreamRemoteIcon;
    expect(remoteIcon.url, equals('http://example.com/icon.png'));
    expect(remoteIcon.width, equals(64));
    expect(remoteIcon.height, equals(128));
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
}
