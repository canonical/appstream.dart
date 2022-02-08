import 'utils.dart';

/// Types of release.
enum AppstreamReleaseType { stable, development }

/// How important this release is to be installed.
enum AppstreamReleaseUrgency { low, medium, high, critical }

/// Types of issues.
enum AppstreamIssueType { generic, cve }

/// Metadata about issue in an issue tracker.
class AppstreamIssue {
  /// The type of issue this is.
  final AppstreamIssueType type;

  /// The ID for this issue, the form of which depends on the issue [type].
  final String id;

  /// URL to more information about this issue.
  final String? url;

  const AppstreamIssue(this.id,
      {this.type = AppstreamIssueType.generic, this.url});

  @override
  bool operator ==(other) =>
      other is AppstreamIssue &&
      other.type == type &&
      other.id == id &&
      other.url == url;

  @override
  int get hashCode => type.hashCode | id.hashCode | url.hashCode;

  @override
  String toString() => "$runtimeType('$id', type: $type, url: $url)";
}

/// Metadata about an available release for a component.
class AppstreamRelease {
  /// The version of this release.
  final String? version;

  /// When this release occurred.
  final DateTime? date;

  /// The type of release this is.
  final AppstreamReleaseType type;

  /// How important this release is to be installed.
  final AppstreamReleaseUrgency urgency;

  /// Description of release, keyed by language.
  final Map<String, String> description;

  /// Link to more information about this release.
  final String? url;

  /// Issues resolved by this release.
  final List<AppstreamIssue> issues;

  const AppstreamRelease(
      {this.version,
      this.date,
      this.type = AppstreamReleaseType.stable,
      this.urgency = AppstreamReleaseUrgency.medium,
      this.description = const {},
      this.url,
      this.issues = const []});

  @override
  bool operator ==(other) =>
      other is AppstreamRelease &&
      other.version == version &&
      other.date == date &&
      other.type == type &&
      other.urgency == urgency &&
      mapsEqual(other.description, description) &&
      other.url == url &&
      listsEqual(other.issues, issues);

  @override
  int get hashCode =>
      version.hashCode |
      date.hashCode |
      type.hashCode |
      urgency.hashCode |
      description.hashCode |
      url.hashCode |
      issues.hashCode;

  @override
  String toString() =>
      '$runtimeType(version: $version, date: $date, type: $type, urgency: $urgency, description: $description, url: $url, issues: $issues)';
}
