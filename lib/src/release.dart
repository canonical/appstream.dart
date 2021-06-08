import 'utils.dart';

enum AppstreamReleaseType { stable, development }

enum AppstreamReleaseUrgency { low, medium, high, critical }

enum AppstreamIssueType { generic, cve }

class AppstreamIssue {
  final String id;
  final AppstreamIssueType type;
  final String? url;

  const AppstreamIssue(this.id,
      {this.type = AppstreamIssueType.generic, this.url});

  @override
  bool operator ==(other) =>
      other is AppstreamIssue &&
      other.id == id &&
      other.type == type &&
      other.url == url;

  @override
  String toString() => "$runtimeType('$id', type: $type, url: $url)";
}

class AppstreamRelease {
  final String? version;
  final DateTime? date;
  final AppstreamReleaseType type;
  final AppstreamReleaseUrgency urgency;
  final Map<String, String> description;
  final String? url;
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
  String toString() =>
      '$runtimeType(version: $version, date: $date, type: $type, urgency: $urgency, description: $description, url: $url, issues: $issues)';
}
