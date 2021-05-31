import 'dart:io';
import 'package:appstream/appstream.dart';

void main() async {
  var yaml = await File('test.yml').readAsString();
  var doc = AppstreamCollection.fromYAML(yaml);
  print(doc);
  for (var component in doc.components) {
    print(component);
  }
  var xml = await File('test.xml').readAsString();
  doc = AppstreamCollection.fromXML(xml);
  print(doc);
  for (var component in doc.components) {
    print(component);
  }
}
