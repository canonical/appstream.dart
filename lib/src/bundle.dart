enum AppstreamBundleType {
  package,
  limba,
  flatpak,
  appimage,
  snap,
  tarball,
  cabinet,
  linglong,
  sysupdate,
  unknown,
}

/// Metadata about bundle support for a component.
class AppstreamBundle {
  /// The type of appstream bundle
  final AppstreamBundleType type;

  /// The name of the bundle
  final String id;

  const AppstreamBundle(this.id, {required this.type});

  @override
  bool operator ==(other) =>
      other is AppstreamBundle && other.type == type && other.id == id;

  @override
  int get hashCode => Object.hash(type, id);

  @override
  String toString() => '$runtimeType($id, type: $type)';
}
