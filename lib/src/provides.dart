/// A firmware type.
enum AppstreamFirmwareType { runtime, flashed }

/// A DBus bus.
enum AppstreamDBusType { user, session, system }

/// Metadata about a thing an Appstream component provides.
class AppstreamProvides {
  const AppstreamProvides();
}

/// Metadata about an media type this component can handle.
class AppstreamProvidesMediatype extends AppstreamProvides {
  /// The media type, e.g. 'image/png'.
  final String mediaType;

  const AppstreamProvidesMediatype(this.mediaType);

  @override
  bool operator ==(other) =>
      other is AppstreamProvidesMediatype && other.mediaType == mediaType;

  @override
  int get hashCode => mediaType.hashCode;

  @override
  String toString() => '$runtimeType($mediaType)';
}

/// Metadata about a library an Appstream component provides.
class AppstreamProvidesLibrary extends AppstreamProvides {
  /// The name of the library, e.g. 'libawesome.so.1'
  final String libraryName;

  const AppstreamProvidesLibrary(this.libraryName);

  @override
  bool operator ==(other) =>
      other is AppstreamProvidesLibrary && other.libraryName == libraryName;

  @override
  int get hashCode => libraryName.hashCode;

  @override
  String toString() => '$runtimeType($libraryName)';
}

/// Metadata about a binary an Appstream component provides.
class AppstreamProvidesBinary extends AppstreamProvides {
  /// The name of the binary, e.g. 'my_app'.
  final String binaryName;

  const AppstreamProvidesBinary(this.binaryName);

  @override
  bool operator ==(other) =>
      other is AppstreamProvidesBinary && other.binaryName == binaryName;

  @override
  int get hashCode => binaryName.hashCode;

  @override
  String toString() => '$runtimeType($binaryName)';
}

/// Metadata about a font an Appstream component provides.
class AppstreamProvidesFont extends AppstreamProvides {
  /// The name of the font, e.g. 'Ubuntu Bold'.
  final String fontName;

  const AppstreamProvidesFont(this.fontName);

  @override
  bool operator ==(other) =>
      other is AppstreamProvidesFont && other.fontName == fontName;

  @override
  int get hashCode => fontName.hashCode;

  @override
  String toString() => '$runtimeType($fontName)';
}

/// Metadata about hardware an Appstream component can handle.
class AppstreamProvidesModalias extends AppstreamProvides {
  /// A modalias glob, e.g. 'usb:v25FBp0160d*'
  final String modalias;

  const AppstreamProvidesModalias(this.modalias);

  @override
  bool operator ==(other) =>
      other is AppstreamProvidesModalias && other.modalias == modalias;

  @override
  int get hashCode => modalias.hashCode;

  @override
  String toString() => '$runtimeType($modalias)';
}

/// Metadata about firmware an Appstream component provides.
class AppstreamProvidesFirmware extends AppstreamProvides {
  /// The type of firmware.
  final AppstreamFirmwareType type;

  /// The name of the firmware.
  final String name;

  const AppstreamProvidesFirmware(this.type, this.name);

  @override
  bool operator ==(other) =>
      other is AppstreamProvidesFirmware &&
      other.type == type &&
      other.name == name;

  @override
  int get hashCode => Object.hash(type, name);

  @override
  String toString() => "$runtimeType($type, '$name')";
}

/// Metadata about a Python 2 module an Appstream component provides.
class AppstreamProvidesPython2 extends AppstreamProvides {
  /// Name of a Python 2 module, e.g. 'mymodule'.
  final String moduleName;

  const AppstreamProvidesPython2(this.moduleName);

  @override
  bool operator ==(other) =>
      other is AppstreamProvidesPython2 && other.moduleName == moduleName;

  @override
  int get hashCode => moduleName.hashCode;

  @override
  String toString() => '$runtimeType($moduleName)';
}

/// Metadata about a Python 3 module an Appstream component provides.
class AppstreamProvidesPython3 extends AppstreamProvides {
  /// Name of a Python 3 module, e.g. 'mymodule3'.
  final String moduleName;

  const AppstreamProvidesPython3(this.moduleName);

  @override
  bool operator ==(other) =>
      other is AppstreamProvidesPython3 && other.moduleName == moduleName;

  @override
  int get hashCode => moduleName.hashCode;

  @override
  String toString() => '$runtimeType($moduleName)';
}

/// Metadata about a D-Bus name an Appstream component provides.
class AppstreamProvidesDBus extends AppstreamProvides {
  /// The bus this name is on.
  final AppstreamDBusType busType;

  /// The name used on the bus, e.g. 'com.example.MyService'.
  final String busName;

  const AppstreamProvidesDBus(this.busType, this.busName);

  @override
  bool operator ==(other) =>
      other is AppstreamProvidesDBus &&
      other.busType == busType &&
      other.busName == busName;

  @override
  int get hashCode => Object.hash(busType, busName);

  @override
  String toString() => '$runtimeType($busType, $busName)';
}

/// Metadata about another Appstream component that can be relaced.
class AppstreamProvidesId extends AppstreamProvides {
  /// The ID of the component that can be replaced.
  final String id;

  const AppstreamProvidesId(this.id);

  @override
  bool operator ==(other) => other is AppstreamProvidesId && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => '$runtimeType($id)';
}
