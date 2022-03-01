/// Metadata about language support for a component.
class AppstreamLanguage {
  /// The locale this language is for, e.g. 'en'
  final String locale;

  /// The percentage of translated text available for this language.
  final int? percentage;

  const AppstreamLanguage(this.locale, {this.percentage});

  @override
  bool operator ==(other) =>
      other is AppstreamLanguage &&
      other.locale == locale &&
      other.percentage == percentage;

  @override
  int get hashCode => Object.hash(locale, percentage);

  @override
  String toString() => '$runtimeType($locale, percentage: $percentage)';
}
