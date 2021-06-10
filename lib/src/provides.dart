enum AppstreamFirmwareType { runtime, flashed }

enum AppstreamDBusType { user, system }

class AppstreamProvides {
  const AppstreamProvides();
}

class AppstreamProvidesMediatype extends AppstreamProvides {
  final String mediaType;

  const AppstreamProvidesMediatype(this.mediaType);

  @override
  bool operator ==(other) =>
      other is AppstreamProvidesMediatype && other.mediaType == mediaType;

  @override
  String toString() => '$runtimeType($mediaType)';
}

class AppstreamProvidesLibrary extends AppstreamProvides {
  final String libraryName;

  const AppstreamProvidesLibrary(this.libraryName);

  @override
  bool operator ==(other) =>
      other is AppstreamProvidesLibrary && other.libraryName == libraryName;

  @override
  String toString() => '$runtimeType($libraryName)';
}

class AppstreamProvidesBinary extends AppstreamProvides {
  final String binaryName;

  const AppstreamProvidesBinary(this.binaryName);

  @override
  bool operator ==(other) =>
      other is AppstreamProvidesBinary && other.binaryName == binaryName;

  @override
  String toString() => '$runtimeType($binaryName)';
}

class AppstreamProvidesFont extends AppstreamProvides {
  final String fontName;

  const AppstreamProvidesFont(this.fontName);

  @override
  bool operator ==(other) =>
      other is AppstreamProvidesFont && other.fontName == fontName;

  @override
  String toString() => '$runtimeType($fontName)';
}

class AppstreamProvidesModalias extends AppstreamProvides {
  final String modalias;

  const AppstreamProvidesModalias(this.modalias);

  @override
  bool operator ==(other) =>
      other is AppstreamProvidesModalias && other.modalias == modalias;

  @override
  String toString() => '$runtimeType($modalias)';
}

class AppstreamProvidesFirmware extends AppstreamProvides {
  final AppstreamFirmwareType type;
  final String name;

  const AppstreamProvidesFirmware(this.type, this.name);

  @override
  bool operator ==(other) =>
      other is AppstreamProvidesFirmware &&
      other.type == type &&
      other.name == name;

  @override
  String toString() => "$runtimeType($type, '$name')";
}

class AppstreamProvidesPython2 extends AppstreamProvides {
  final String moduleName;

  const AppstreamProvidesPython2(this.moduleName);

  @override
  bool operator ==(other) =>
      other is AppstreamProvidesPython2 && other.moduleName == moduleName;

  @override
  String toString() => '$runtimeType($moduleName)';
}

class AppstreamProvidesPython3 extends AppstreamProvides {
  final String moduleName;

  const AppstreamProvidesPython3(this.moduleName);

  @override
  bool operator ==(other) =>
      other is AppstreamProvidesPython3 && other.moduleName == moduleName;

  @override
  String toString() => '$runtimeType($moduleName)';
}

class AppstreamProvidesDBus extends AppstreamProvides {
  final AppstreamDBusType busType;
  final String busName;

  const AppstreamProvidesDBus(this.busType, this.busName);

  @override
  bool operator ==(other) =>
      other is AppstreamProvidesDBus &&
      other.busType == busType &&
      other.busName == busName;

  @override
  String toString() => '$runtimeType($busType, $busName)';
}

class AppstreamProvidesId extends AppstreamProvides {
  final String id;

  const AppstreamProvidesId(this.id);

  @override
  bool operator ==(other) => other is AppstreamProvidesId && other.id == id;

  @override
  String toString() => '$runtimeType($id)';
}
