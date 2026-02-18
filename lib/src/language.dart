/// Metadata about language support for a component.
class AppstreamLanguage {
  const AppstreamLanguage(this.locale, {this.percentage});

  /// The locale this language is for, e.g. 'en'
  final String locale;

  /// The percentage of translated text available for this language.
  final int? percentage;

  @override
  bool operator ==(Object other) =>
      other is AppstreamLanguage &&
      other.locale == locale &&
      other.percentage == percentage;

  @override
  int get hashCode => Object.hash(locale, percentage);

  @override
  String toString() => '$runtimeType($locale, percentage: $percentage)';
}
