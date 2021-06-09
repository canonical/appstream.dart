import 'dart:convert';
import 'dart:io';

import 'collection.dart';
import 'component.dart';

/// Metadata for all the components known about on this system.
class AppstreamPool {
  /// The components in this pool.
  final components = <AppstreamComponent>[];

  /// Load the pool.
  Future<void> load() async {
    var xmlPaths = await _listFiles('/var/lib/app-info', ['.xml', '.xml.gz']);
    var collectionFutures = <Future<AppstreamCollection>>[];
    for (var path in xmlPaths) {
      collectionFutures.add(_loadXmlCollection(path));
    }
    var yamlPaths =
        await _listFiles('/var/lib/app-info/yaml', ['.yml', '.yml.gz']);
    for (var path in yamlPaths) {
      collectionFutures.add(_loadYamlCollection(path));
    }
    var collections = await Future.wait(collectionFutures);
    for (var collection in collections) {
      components.addAll(collection.components);
    }
  }

  Future<List<String>> _listFiles(
      String path, Iterable<String> suffixes) async {
    var dir = Directory(path);
    return await dir
        .list()
        .where((e) => e is File)
        .map((e) => (e as File).path)
        .toList();
  }

  Future<AppstreamCollection> _loadXmlCollection(String path) async {
    return AppstreamCollection.fromXml(await _loadFile(path));
  }

  Future<AppstreamCollection> _loadYamlCollection(String path) async {
    return AppstreamCollection.fromYaml(await _loadFile(path));
  }

  Future<String> _loadFile(String path) async {
    var stream = File(path).openRead();
    if (path.endsWith('.gz')) {
      stream = gzip.decoder.bind(stream);
    }

    return await utf8.decoder
        .bind(stream)
        .fold('', (prev, element) => prev + element);
  }
}
