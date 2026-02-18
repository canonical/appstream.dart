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
  const AppstreamProvidesMediatype(this.mediaType);

  /// The media type, e.g. 'image/png'.
  final String mediaType;

  @override
  bool operator ==(Object other) =>
      other is AppstreamProvidesMediatype && other.mediaType == mediaType;

  @override
  int get hashCode => mediaType.hashCode;

  @override
  String toString() => '$runtimeType($mediaType)';
}

/// Metadata about a library an Appstream component provides.
class AppstreamProvidesLibrary extends AppstreamProvides {
  const AppstreamProvidesLibrary(this.libraryName);

  /// The name of the library, e.g. 'libawesome.so.1'
  final String libraryName;

  @override
  bool operator ==(Object other) =>
      other is AppstreamProvidesLibrary && other.libraryName == libraryName;

  @override
  int get hashCode => libraryName.hashCode;

  @override
  String toString() => '$runtimeType($libraryName)';
}

/// Metadata about a binary an Appstream component provides.
class AppstreamProvidesBinary extends AppstreamProvides {
  const AppstreamProvidesBinary(this.binaryName);

  /// The name of the binary, e.g. 'my_app'.
  final String binaryName;

  @override
  bool operator ==(Object other) =>
      other is AppstreamProvidesBinary && other.binaryName == binaryName;

  @override
  int get hashCode => binaryName.hashCode;

  @override
  String toString() => '$runtimeType($binaryName)';
}

/// Metadata about a font an Appstream component provides.
class AppstreamProvidesFont extends AppstreamProvides {
  const AppstreamProvidesFont(this.fontName);

  /// The name of the font, e.g. 'Ubuntu Bold'.
  final String fontName;

  @override
  bool operator ==(Object other) =>
      other is AppstreamProvidesFont && other.fontName == fontName;

  @override
  int get hashCode => fontName.hashCode;

  @override
  String toString() => '$runtimeType($fontName)';
}

/// Metadata about hardware an Appstream component can handle.
class AppstreamProvidesModalias extends AppstreamProvides {
  const AppstreamProvidesModalias(this.modalias);

  /// A modalias glob, e.g. 'usb:v25FBp0160d*'
  final String modalias;

  @override
  bool operator ==(Object other) =>
      other is AppstreamProvidesModalias && other.modalias == modalias;

  @override
  int get hashCode => modalias.hashCode;

  @override
  String toString() => '$runtimeType($modalias)';
}

/// Metadata about firmware an Appstream component provides.
class AppstreamProvidesFirmware extends AppstreamProvides {
  const AppstreamProvidesFirmware(this.type, this.name);

  /// The type of firmware.
  final AppstreamFirmwareType type;

  /// The name of the firmware.
  final String name;

  @override
  bool operator ==(Object other) =>
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
  const AppstreamProvidesPython2(this.moduleName);

  /// Name of a Python 2 module, e.g. 'mymodule'.
  final String moduleName;

  @override
  bool operator ==(Object other) =>
      other is AppstreamProvidesPython2 && other.moduleName == moduleName;

  @override
  int get hashCode => moduleName.hashCode;

  @override
  String toString() => '$runtimeType($moduleName)';
}

/// Metadata about a Python 3 module an Appstream component provides.
class AppstreamProvidesPython3 extends AppstreamProvides {
  const AppstreamProvidesPython3(this.moduleName);

  /// Name of a Python 3 module, e.g. 'mymodule3'.
  final String moduleName;

  @override
  bool operator ==(Object other) =>
      other is AppstreamProvidesPython3 && other.moduleName == moduleName;

  @override
  int get hashCode => moduleName.hashCode;

  @override
  String toString() => '$runtimeType($moduleName)';
}

/// Metadata about a D-Bus name an Appstream component provides.
class AppstreamProvidesDBus extends AppstreamProvides {
  const AppstreamProvidesDBus(this.busType, this.busName);

  /// The bus this name is on.
  final AppstreamDBusType busType;

  /// The name used on the bus, e.g. 'com.example.MyService'.
  final String busName;

  @override
  bool operator ==(Object other) =>
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
  const AppstreamProvidesId(this.id);

  /// The ID of the component that can be replaced.
  final String id;

  @override
  bool operator ==(Object other) =>
      other is AppstreamProvidesId && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => '$runtimeType($id)';
}
