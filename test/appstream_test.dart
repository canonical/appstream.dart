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
    expect(collection.version, equals('0.12'));
    expect(collection.origin, equals('ubuntu-hirsute-main'));
    expect(collection.architecture, isNull);
    expect(collection.priority, isNull);
    expect(collection.components, hasLength(1));
    var component = collection.components[0];
    expect(component.id, equals('com.example.Hello'));
    expect(component.type, equals('console-application'));
    expect(component.package, equals('hello'));
    expect(component.name, equals({'C': 'Hello World'}));
    expect(component.summary, equals({'C': 'A simple example application'}));
    expect(component.icons, isEmpty);
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
    expect(collection.version, equals('0.12'));
    expect(collection.origin, equals('ubuntu-hirsute-main'));
    expect(collection.architecture, isNull);
    expect(collection.priority, isNull);
    expect(collection.components, hasLength(1));
    var component = collection.components[0];
    expect(component.id, equals('com.example.Hello'));
    expect(component.type, equals('console-application'));
    expect(component.package, equals('hello'));
    expect(component.name, equals({'C': 'Hello World'}));
    expect(component.summary, equals({'C': 'A simple example application'}));
    expect(component.icons, isEmpty);
  });
}
