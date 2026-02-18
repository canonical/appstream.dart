import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:appstream/src/collection.dart';
import 'package:appstream/src/component.dart';

class _LoadCollectionArguments {
  const _LoadCollectionArguments(this.port, this.path);
  final SendPort port;
  final String path;
}

/// Metadata for all the components known about on this system.
class AppstreamPool {
  /// The components in this pool.
  final components = <AppstreamComponent>[];

  /// Load the pool.
  Future<void> load() async {
    final catalogDirPrefixes = ['/usr/share', '/var/lib', '/var/cache'];

    final catalogDirs = <String>[];
    for (final prefix in catalogDirPrefixes) {
      final catalogPath = '$prefix/swcatalog';
      final catalogLegacyPath = '$prefix/app-info';

      // Only use the legacy path if it's not a symlink to the current path.
      var ignoreLegacyPath = false;
      final legacyLink = Link(catalogLegacyPath);
      ignoreLegacyPath =
          await legacyLink.exists() && await legacyLink.target() == catalogPath;

      catalogDirs.add(catalogPath);
      if (!ignoreLegacyPath) {
        catalogDirs.add(catalogLegacyPath);
      }
    }

    final collectionFutures = <Future<AppstreamCollection>>[];
    for (final dir in catalogDirs) {
      final xmlPaths = await _listFiles(dir, ['.xml', '.xml.gz']);
      for (final path in xmlPaths) {
        collectionFutures.add(_loadXmlCollection(path));
      }
      final yamlPaths = await _listFiles('$dir/yaml', ['.yml', '.yml.gz']);
      for (final path in yamlPaths) {
        collectionFutures.add(_loadYamlCollection(path));
      }
    }
    final collections = await Future.wait(collectionFutures);
    for (final collection in collections) {
      components.addAll(collection.components);
    }
  }

  static Future<List<String>> _listFiles(
    String path,
    Iterable<String> suffixes,
  ) async {
    final dir = Directory(path);
    try {
      return await dir
          .list()
          .where((e) => e is File)
          .map((e) => (e as File).path)
          .toList();
    } on FileSystemException {
      return [];
    }
  }

  static Future<AppstreamCollection> _loadCollection(
    void Function(_LoadCollectionArguments args) entryPoint,
    String path,
  ) async {
    final port = ReceivePort();
    final isolate = await Isolate.spawn<_LoadCollectionArguments>(
      entryPoint,
      _LoadCollectionArguments(port.sendPort, path),
    );
    final collection = await port.first;
    isolate.kill(priority: Isolate.immediate);
    return collection as AppstreamCollection;
  }

  static Future<AppstreamCollection> _loadXmlCollection(String path) =>
      _loadCollection(_loadXmlCollectionInIsolate, path);

  static Future<void> _loadXmlCollectionInIsolate(
    _LoadCollectionArguments args,
  ) async {
    args.port.send(AppstreamCollection.fromXml(await _loadFile(args.path)));
  }

  static Future<AppstreamCollection> _loadYamlCollection(String path) =>
      _loadCollection(_loadYamlCollectionInIsolate, path);

  static Future<void> _loadYamlCollectionInIsolate(
    _LoadCollectionArguments args,
  ) async {
    args.port.send(AppstreamCollection.fromYaml(await _loadFile(args.path)));
  }

  static Future<String> _loadFile(String path) async {
    var stream = File(path).openRead();
    if (path.endsWith('.gz')) {
      stream = gzip.decoder.bind(stream);
    }

    return utf8.decoder.bind(stream).join();
  }
}
