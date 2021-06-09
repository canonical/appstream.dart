class AppstreamLanguage {
  final String locale;
  final int? percentage;

  const AppstreamLanguage(this.locale, {this.percentage});

  @override
  bool operator ==(other) =>
      other is AppstreamLanguage &&
      other.locale == locale &&
      other.percentage == percentage;

  @override
  String toString() => "$runtimeType($locale, percentage: $percentage)";
}
