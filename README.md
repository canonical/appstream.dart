[![Pub Package](https://img.shields.io/pub/v/appstream.svg)](https://pub.dev/packages/appstream)

A parser for [Appstream](https://www.freedesktop.org/software/appstream) data.
This package allows Dart applications to access package metadata on Linux systems.

```dart
import 'package:appstream/appstream.dart';

var pool = AppstreamPool();
await pool.load();
for (var component in pool.components) {
  print(component);
}
```

## Contributing to appstream.dart

We welcome contributions! See the [contribution guide](CONTRIBUTING.md) for more details.
