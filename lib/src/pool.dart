import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:appstream/src/codec.dart';
import 'package:appstream/src/collection.dart';
import 'package:appstream/src/component.dart';

class _LoadCollectionArguments {
  const _LoadCollectionArguments(this.port, this.path, this.locales);
  final SendPort port;
  final String path;
  final Set<String>? locales;
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
  AppstreamPool({List<String>? catalogDirPrefixes, Iterable<String>? locales})
      : catalogDirPrefixes = catalogDirPrefixes ??
            const ['/usr/share', '/var/lib', '/var/cache'],
        _locales = locales?.toSet();

  /// Where `swcatalog` and `app-info` are searched; defaults to system dirs.
  final List<String> catalogDirPrefixes;

  final Set<String>? _locales;

  /// The components in this pool, read-only and decoded as they are used.
  List<AppstreamComponent> get components => _components;

  var _components = _EncodedComponentList(const []);

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

    // The loaders start together at the end: one that fails early would have
    // no listener yet while the directories are still being listed.
    final loaders = <Future<EncodedComponents> Function()>[];
    for (final dir in catalogDirs) {
      final xmlPaths = await _listFiles(dir, ['.xml', '.xml.gz']);
      for (final path in xmlPaths) {
        loaders.add(() => _loadCollection(_loadXmlCollectionInIsolate, path));
      }
      final yamlPaths = await _listFiles('$dir/yaml', ['.yml', '.yml.gz']);
      for (final path in yamlPaths) {
        loaders.add(() => _loadCollection(_loadYamlCollectionInIsolate, path));
      }
    }
    final chunks = await Future.wait([for (final load in loaders) load()]);
    _components = _EncodedComponentList(chunks);
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

  Future<EncodedComponents> _loadCollection(
    void Function(_LoadCollectionArguments args) entryPoint,
    String path,
  ) async {
    final port = ReceivePort();
    final errorPort = ReceivePort();
    final isolate = await Isolate.spawn<_LoadCollectionArguments>(
      entryPoint,
      _LoadCollectionArguments(port.sendPort, path, _locales),
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
      return collection as EncodedComponents;
    } finally {
      port.close();
      errorPort.close();
      isolate.kill(priority: Isolate.immediate);
    }
  }

  // Isolate.exit hands over the bytes without copying them.
  static Future<void> _loadXmlCollectionInIsolate(
    _LoadCollectionArguments args,
  ) async {
    final xml = await _loadFile(args.path);
    final collection = AppstreamCollection.fromXml(
      xml,
      locales: args.locales,
    );
    Isolate.exit(args.port, EncodedComponents.encode(collection.components));
  }

  static void _loadYamlCollectionInIsolate(_LoadCollectionArguments args) {
    final file = File(args.path).openSync();
    final encoded = EncodedComponentsBuilder();
    try {
      AppstreamCollection.fromYamlLines(
        _readLines(file, args.path.endsWith('.gz')),
        locales: args.locales,
        onComponent: encoded.add,
      );
    } finally {
      file.closeSync();
    }
    // Isolate.exit never returns, so the file has to be closed before it.
    Isolate.exit(args.port, encoded.build());
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

/// Reads [EncodedComponents] as one list; indexing keeps what it decodes.
class _EncodedComponentList extends ListBase<AppstreamComponent> {
  _EncodedComponentList(this._chunks) {
    var total = 0;
    for (final chunk in _chunks) {
      total += chunk.length;
      _chunkEnds.add(total);
    }
  }

  final List<EncodedComponents> _chunks;

  // Cumulative lengths, so an index finds its chunk.
  final _chunkEnds = <int>[];

  final _read = <int, AppstreamComponent>{};

  @override
  int get length => _chunkEnds.isEmpty ? 0 : _chunkEnds.last;

  @override
  set length(int newLength) => throw UnsupportedError(
        'Cannot change the length of an unmodifiable list',
      );

  @override
  AppstreamComponent operator [](int index) {
    RangeError.checkValidIndex(index, this);
    return _read[index] ??= _decode(index);
  }

  @override
  void operator []=(int index, AppstreamComponent value) =>
      throw UnsupportedError('Cannot modify an unmodifiable list');

  @override
  Iterator<AppstreamComponent> get iterator => _decodeAll().iterator;

  // Scanning keeps nothing, so a pass over the catalog does not fill the cache.
  Iterable<AppstreamComponent> _decodeAll() sync* {
    var index = 0;
    for (final chunk in _chunks) {
      for (var i = 0; i < chunk.length; i++) {
        yield _read[index++] ?? chunk[i];
      }
    }
  }

  AppstreamComponent _decode(int index) {
    var chunk = 0;
    while (_chunkEnds[chunk] <= index) {
      chunk++;
    }
    final start = chunk == 0 ? 0 : _chunkEnds[chunk - 1];
    return _chunks[chunk][index - start];
  }
}
