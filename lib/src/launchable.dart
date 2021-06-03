class AppstreamLaunchable {
  const AppstreamLaunchable();
}

class AppstreamLaunchableDesktopId extends AppstreamLaunchable {
  final String desktopId;

  const AppstreamLaunchableDesktopId(this.desktopId);

  @override
  bool operator ==(other) =>
      other is AppstreamLaunchableDesktopId && other.desktopId == desktopId;

  @override
  String toString() => '$runtimeType($desktopId)';
}

class AppstreamLaunchableService extends AppstreamLaunchable {
  final String serviceName;

  const AppstreamLaunchableService(this.serviceName);

  @override
  bool operator ==(other) =>
      other is AppstreamLaunchableService && other.serviceName == serviceName;

  @override
  String toString() => '$runtimeType($serviceName)';
}

class AppstreamLaunchableCockpitManifest extends AppstreamLaunchable {
  final String packageName;

  const AppstreamLaunchableCockpitManifest(this.packageName);

  @override
  bool operator ==(other) =>
      other is AppstreamLaunchableCockpitManifest &&
      other.packageName == packageName;

  @override
  String toString() => '$runtimeType($packageName)';
}

class AppstreamLaunchableUrl extends AppstreamLaunchable {
  final String url;

  const AppstreamLaunchableUrl(this.url);

  @override
  bool operator ==(other) =>
      other is AppstreamLaunchableUrl && other.url == url;

  @override
  String toString() => '$runtimeType($url)';
}
