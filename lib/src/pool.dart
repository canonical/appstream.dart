import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'collection.dart';
import 'component.dart';

class _IsolateArguments {
  const _IsolateArguments(this.port, this.path);
  final SendPort port;
  final String path;
}

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

  static Future<List<String>> _listFiles(
      String path, Iterable<String> suffixes) async {
    var dir = Directory(path);
    return await dir
        .list()
        .where((e) => e is File)
        .map((e) => (e as File).path)
        .toList();
  }

  static Future<AppstreamCollection> _loadCollection(
      void Function(_IsolateArguments args) entryPoint, String path) async {
    ReceivePort port = ReceivePort();
    final isolate = await Isolate.spawn<_IsolateArguments>(
        entryPoint, _IsolateArguments(port.sendPort, path));
    final collection = await port.first;
    isolate.kill(priority: Isolate.immediate);
    return collection;
  }

  static Future<AppstreamCollection> _loadXmlCollection(String path) =>
      _loadCollection(_loadXmlCollectionInIsolate, path);

  static void _loadXmlCollectionInIsolate(_IsolateArguments args) async {
    args.port.send(AppstreamCollection.fromXml(await _loadFile(args.path)));
  }

  static Future<AppstreamCollection> _loadYamlCollection(String path) =>
      _loadCollection(_loadYamlCollectionInIsolate, path);

  static void _loadYamlCollectionInIsolate(_IsolateArguments args) async {
    args.port.send(AppstreamCollection.fromYaml(await _loadFile(args.path)));
  }

  static Future<String> _loadFile(String path) async {
    var stream = File(path).openRead();
    if (path.endsWith('.gz')) {
      stream = gzip.decoder.bind(stream);
    }

    return await utf8.decoder
        .bind(stream)
        .fold('', (prev, element) => prev + element);
  }
}
