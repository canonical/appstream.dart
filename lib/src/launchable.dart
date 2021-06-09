/// Metadata about something that can be launched from a component.
class AppstreamLaunchable {
  const AppstreamLaunchable();
}

/// Metadata about an application that can be launched via a desktop file.
class AppstreamLaunchableDesktopId extends AppstreamLaunchable {
  /// The ID of a desktop file, e.g. 'myapp.desktop'.
  final String desktopId;

  const AppstreamLaunchableDesktopId(this.desktopId);

  @override
  bool operator ==(other) =>
      other is AppstreamLaunchableDesktopId && other.desktopId == desktopId;

  @override
  String toString() => '$runtimeType($desktopId)';
}

/// Metadata about a service that can be launched from a component.
class AppstreamLaunchableService extends AppstreamLaunchable {
  /// The name of the service, e.g. 'myservice'.
  final String serviceName;

  const AppstreamLaunchableService(this.serviceName);

  @override
  bool operator ==(other) =>
      other is AppstreamLaunchableService && other.serviceName == serviceName;

  @override
  String toString() => '$runtimeType($serviceName)';
}

/// Metadata about a [Cockpit package](https://cockpit-project.org/guide/latest/packages.html) that can be launched from a component.
class AppstreamLaunchableCockpitManifest extends AppstreamLaunchable {
  /// A [Cockpit package name](https://cockpit-project.org/guide/latest/packages.html).
  final String packageName;

  const AppstreamLaunchableCockpitManifest(this.packageName);

  @override
  bool operator ==(other) =>
      other is AppstreamLaunchableCockpitManifest &&
      other.packageName == packageName;

  @override
  String toString() => '$runtimeType($packageName)';
}

/// Metadata for components that are web applications.
class AppstreamLaunchableUrl extends AppstreamLaunchable {
  /// A URL for this application, e.g. 'https://example.com/myapp'.
  final String url;

  const AppstreamLaunchableUrl(this.url);

  @override
  bool operator ==(other) =>
      other is AppstreamLaunchableUrl && other.url == url;

  @override
  String toString() => '$runtimeType($url)';
}
