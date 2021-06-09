import 'icon.dart';
import 'language.dart';
import 'launchable.dart';
import 'provides.dart';
import 'release.dart';
import 'screenshot.dart';
import 'url.dart';

/// Types of Appstream component.
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

/// Rating applied to an aspect of a component, e.g. the language used within it.
enum AppstreamContentRating { none, mild, moderate, intense }

/// Metadata about a component (application, font etc).
class AppstreamComponent {
  /// Unique ID for this component.
  final String id;

  /// Type of component.
  final AppstreamComponentType type;

  /// The name of the package this component is provided by.
  final String package;

  /// Human readable name of the component, keyed by language.
  final Map<String, String> name;

  /// Short summary of the component, keyed by language.
  final Map<String, String> summary;

  /// Long description of the component, keyed by language.
  final Map<String, String> description;

  /// The developer or project responsible for this project, keyed by langauge.
  final Map<String, String> developerName;

  /// The license this project is under
  final String? projectLicense;

  /// Umbrella project this component is part of, e.g. 'GNOME'.
  final String? projectGroup;

  /// Icons for this component.
  final List<AppstreamIcon> icons;

  /// Web links for this component.
  final List<AppstreamUrl> urls;

  /// Categories this component fits.
  final List<String> categories;

  /// Search keywords for this component, keyed by language.
  final Map<String, List<String>> keywords;

  /// Screenshots of this component.
  final List<AppstreamScreenshot> screenshots;

  /// Desktops that require this component, e.g. 'GNOME'
  final List<String> compulsoryForDesktops;

  /// Releases for this component.
  final List<AppstreamRelease> releases;

  /// Things this component provides.
  final List<AppstreamProvides> provides;

  /// Things that can be launched from this component.
  final List<AppstreamLaunchable> launchables;

  /// Languages this component is available in.
  final List<AppstreamLanguage> languages;

  /// Content ratings for this package, keyed by content rating system name. e.g. {'oars-1.0': {'drugs-alcohol': AppstreamContentRating.moderate, 'language-humor': AppstreamContentRating.mild}}
  final Map<String, Map<String, AppstreamContentRating>> contentRatings;

  /// Creates a new Appstream component.
  const AppstreamComponent(
      {required this.id,
      required this.type,
      required this.package,
      required this.name,
      required this.summary,
      this.description = const {},
      this.developerName = const {},
      this.projectLicense,
      this.projectGroup,
      this.icons = const [],
      this.urls = const [],
      this.categories = const [],
      this.keywords = const {},
      this.screenshots = const [],
      this.compulsoryForDesktops = const [],
      this.releases = const [],
      this.provides = const [],
      this.launchables = const [],
      this.languages = const [],
      this.contentRatings = const {}});

  @override
  String toString() =>
      "$runtimeType(id: $id, type: $type, package: $package, name: $name, summary: $summary, description: $description, developerName: '$developerName', projectLicense: $projectLicense, projectGroup: $projectGroup, icons: $icons, urls: $urls, categories: $categories, keywords: $keywords, screenshots: $screenshots, compulsoryForDesktops: $compulsoryForDesktops, release: $releases, provides: $provides, launchables: $launchables, languages: $languages, contentRatings: $contentRatings)";
}
