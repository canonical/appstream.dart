/// Metadata about something that can be launched from a component.
class AppstreamLaunchable {
  const AppstreamLaunchable();
}

/// Metadata about an application that can be launched via a desktop file.
class AppstreamLaunchableDesktopId extends AppstreamLaunchable {
  const AppstreamLaunchableDesktopId(this.desktopId);

  /// The ID of a desktop file, e.g. 'myapp.desktop'.
  final String desktopId;

  @override
  bool operator ==(Object other) =>
      other is AppstreamLaunchableDesktopId && other.desktopId == desktopId;

  @override
  int get hashCode => desktopId.hashCode;

  @override
  String toString() => '$runtimeType($desktopId)';
}

/// Metadata about a service that can be launched from a component.
class AppstreamLaunchableService extends AppstreamLaunchable {
  const AppstreamLaunchableService(this.serviceName);

  /// The name of the service, e.g. 'myservice'.
  final String serviceName;

  @override
  bool operator ==(Object other) =>
      other is AppstreamLaunchableService && other.serviceName == serviceName;

  @override
  int get hashCode => serviceName.hashCode;

  @override
  String toString() => '$runtimeType($serviceName)';
}

/// Metadata about a [Cockpit package](https://cockpit-project.org/guide/latest/packages.html) that can be launched from a component.
class AppstreamLaunchableCockpitManifest extends AppstreamLaunchable {
  const AppstreamLaunchableCockpitManifest(this.packageName);

  /// A [Cockpit package name](https://cockpit-project.org/guide/latest/packages.html).
  final String packageName;

  @override
  bool operator ==(Object other) =>
      other is AppstreamLaunchableCockpitManifest &&
      other.packageName == packageName;

  @override
  int get hashCode => packageName.hashCode;

  @override
  String toString() => '$runtimeType($packageName)';
}

/// Metadata for components that are web applications.
class AppstreamLaunchableUrl extends AppstreamLaunchable {
  const AppstreamLaunchableUrl(this.url);

  /// A URL for this application, e.g. 'https://example.com/myapp'.
  final String url;

  @override
  bool operator ==(Object other) =>
      other is AppstreamLaunchableUrl && other.url == url;

  @override
  int get hashCode => url.hashCode;

  @override
  String toString() => '$runtimeType($url)';
}
