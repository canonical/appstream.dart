import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:appstream/src/collection.dart';
import 'package:appstream/src/component.dart';

class _LoadCollectionArguments {
  const _LoadCollectionArguments(this.port, this.path, this.locales, this.omit);
  final SendPort port;
  final String path;
  final List<String>? locales;
  final List<AppstreamDetail> omit;
}

/// Thrown when a catalog file cannot be loaded, for instance because it holds
/// metadata this package cannot parse.
class AppstreamCollectionLoadException implements Exception {
  const AppstreamCollectionLoadException(this.path, this.message);

  /// Path of the catalog file that failed to load.
  final String path;

  /// Description of the underlying failure.
  final String message;

  @override
  String toString() =>
      'AppstreamCollectionLoadException: failed to load $path: $message';
}

/// Metadata for all the components known about on this system.
class AppstreamPool {
  /// Creates a pool keeping only [locales] translations plus `C` (null: all).
  AppstreamPool({
    List<String>? catalogDirPrefixes,
    List<String>? locales,
    List<AppstreamDetail> omit = const [],
  })  : catalogDirPrefixes = catalogDirPrefixes ??
            const ['/usr/share', '/var/lib', '/var/cache'],
        _locales = locales,
        _omit = omit;

  /// Where `swcatalog` and `app-info` are searched; defaults to system dirs.
  final List<String> catalogDirPrefixes;

  final List<String>? _locales;

  final List<AppstreamDetail> _omit;

  /// The components in this pool, read-only.
  List<AppstreamComponent> get components => _components;

  var _components = const <AppstreamComponent>[];

  /// Load the pool, replacing the components it held before.
  Future<void> load() async {
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

    // Start loaders together so early failures do not fire before listeners attach.
    final loaders = <Future<AppstreamCollection> Function()>[];
    for (final dir in catalogDirs) {
      final xmlPaths = await _listFiles(dir, ['.xml', '.xml.gz']);
      for (final path in xmlPaths) {
        loaders.add(() => _loadCollection(_xmlIsolateEntryPoint, path));
      }
      final yamlPaths = await _listFiles('$dir/yaml', ['.yml', '.yml.gz']);
      for (final path in yamlPaths) {
        loaders.add(() => _loadCollection(_yamlIsolateEntryPoint, path));
      }
    }
    final collections = await Future.wait([for (final load in loaders) load()]);
    final allComponents = <AppstreamComponent>[];
    for (final collection in collections) {
      allComponents.addAll(collection.components);
    }
    _components = List.unmodifiable(allComponents);
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

  Future<AppstreamCollection> _loadCollection(
    void Function(_LoadCollectionArguments args) entryPoint,
    String path,
  ) async {
    final port = ReceivePort();
    final errorPort = ReceivePort();
    final isolate = await Isolate.spawn<_LoadCollectionArguments>(
      entryPoint,
      _LoadCollectionArguments(port.sendPort, path, _locales, _omit),
      onError: errorPort.sendPort,
    );
    try {
      // An isolate that dies before sending never closes `port`, so waiting on
      // it alone hangs forever. Race the result against the error port so a
      // failure to parse surfaces as an exception instead.
      final collection = await Future.any([
        port.first,
        errorPort.first.then(
          (error) => throw AppstreamCollectionLoadException(
            path,
            (error as List).first.toString(),
          ),
        ),
      ]);
      return collection as AppstreamCollection;
    } finally {
      port.close();
      errorPort.close();
      isolate.kill(priority: Isolate.immediate);
    }
  }

  /// [Isolate.spawn] entry point only: [Isolate.exit] ends the calling isolate.
  static Future<void> _xmlIsolateEntryPoint(
    _LoadCollectionArguments args,
  ) async {
    final xml = await _loadFile(args.path);
    final collection = AppstreamCollection.fromXml(
      xml,
      locales: args.locales,
      omit: args.omit,
    );
    // Isolate.exit hands over the collection without copying.
    Isolate.exit(args.port, collection);
  }

  /// [Isolate.spawn] entry point only: [Isolate.exit] ends the calling isolate.
  static void _yamlIsolateEntryPoint(_LoadCollectionArguments args) {
    final file = File(args.path).openSync();
    final AppstreamCollection collection;
    try {
      collection = AppstreamCollection.fromYamlLines(
        _readLines(file, args.path.endsWith('.gz')),
        locales: args.locales,
        omit: args.omit,
      );
    } finally {
      file.closeSync();
    }
    // Outside the try: Isolate.exit would skip the finally and leak the file.
    Isolate.exit(args.port, collection);
  }

  static Future<String> _loadFile(String path) async {
    var stream = File(path).openRead();
    if (path.endsWith('.gz')) {
      stream = gzip.decoder.bind(stream);
    }

    return utf8.decoder.bind(stream).join();
  }

  /// [file] stays open: a `finally` here won't run if iteration stops early.
  static Iterable<String> _readLines(RandomAccessFile file, bool gunzip) sync* {
    final lines = _LineSink();
    Sink<List<int>> input = utf8.decoder
        .startChunkedConversion(LineSplitter().startChunkedConversion(lines));
    if (gunzip) {
      input = gzip.decoder.startChunkedConversion(input);
    }
    while (true) {
      // Blocking is fine in an isolate; 64 KiB is File.openRead's block size.
      final chunk = file.readSync(64 * 1024);
      if (chunk.isEmpty) {
        break;
      }
      input.add(chunk);
      yield* lines.take();
    }
    input.close();
    yield* lines.take();
  }
}

class _LineSink implements Sink<String> {
  var _lines = <String>[];

  /// Returns the lines collected since the last call.
  List<String> take() {
    final lines = _lines;
    _lines = <String>[];
    return lines;
  }

  @override
  void add(String line) => _lines.add(line);

  @override
  void close() {}
}
