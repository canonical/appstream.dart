import 'package:appstream/appstream.dart';
import 'package:test/test.dart';

void main() {
  test('empty collection - xml', () async {
    expect(() => AppstreamCollection.fromXml(''), throwsFormatException);
  });

  test('minimal collection - xml', () async {
    var collection = AppstreamCollection.fromXml(
        "<components><version>0.12</version><origin>ubuntu-hirsute-main</origin></components>\n");
    expect(collection.version, equals('0.12'));
    expect(collection.origin, equals('ubuntu-hirsute-main'));
    expect(collection.architecture, isNull);
    expect(collection.priority, isNull);
    expect(collection.components, isEmpty);
  });

  test('empty collection - yaml', () async {
    expect(() => AppstreamCollection.fromYaml(''), throwsFormatException);
  });

  test('minimal collection - yaml', () async {
    var collection = AppstreamCollection.fromYaml(
        "---\nFile: DEP-11\nVersion: '0.12'\nOrigin: ubuntu-hirsute-main\n");
    expect(collection.version, equals('0.12'));
    expect(collection.origin, equals('ubuntu-hirsute-main'));
    expect(collection.architecture, isNull);
    expect(collection.priority, isNull);
    expect(collection.components, isEmpty);
  });
}
