import 'icon.dart';
import 'provides.dart';
import 'screenshot.dart';
import 'url.dart';

enum AppstreamComponentType {
  unknown,
  generic,
  desktopApplication,
  consoleApplication,
  webApplication,
  addon,
  font,
  codec,
  inputMethod,
  firmware,
  driver,
  localization,
  service,
  repository,
  operatingSystem,
  iconTheme,
  runtime
}

class AppstreamComponent {
  final String id;
  final AppstreamComponentType type;
  final String package;
  final Map<String, String> name;
  final Map<String, String> summary;
  final Map<String, String> description;
  final String? developerName;
  final String? projectLicense;
  final String? projectGroup;
  final List<AppstreamIcon> icons;
  final List<AppstreamUrl> urls;
  final List<String> categories;
  final Map<String, List<String>> keywords;
  final List<AppstreamScreenshot> screenshots;
  final List<String> compulsoryForDesktops;
  final List<AppstreamProvides> provides;

  const AppstreamComponent(
      {required this.id,
      required this.type,
      required this.package,
      required this.name,
      required this.summary,
      this.description = const {},
      this.developerName,
      this.projectLicense,
      this.projectGroup,
      this.icons = const [],
      this.urls = const [],
      this.categories = const [],
      this.keywords = const {},
      this.screenshots = const [],
      this.compulsoryForDesktops = const [],
      this.provides = const []});

  @override
  String toString() =>
      "$runtimeType(id: $id, type: $type, package: $package, name: $name, summary: $summary, description: $description, developerName: '$developerName', projectLicense: $projectLicense, projectGroup: $projectGroup, icons: $icons, urls: $urls, categories: $categories, keywords: $keywords, screenshots: $screenshots, compulsoryForDesktops: $compulsoryForDesktops, provides: $provides)";
}
