/// Metadata about custom support for a component.
class AppstreamCustom {
  /// The name of the bundle
  final List<Map<String, String>> values;

  const AppstreamCustom(this.values);

  @override
  String toString() => '$runtimeType($values)';
}
