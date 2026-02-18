/// Metadata about custom support for a component.
class AppstreamCustom {
  const AppstreamCustom(this.values);

  /// The name of the bundle
  final List<Map<String, String>> values;

  @override
  String toString() => '$runtimeType($values)';
}
