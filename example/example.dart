import 'package:appstream/appstream.dart';

void main() async {
  var pool = AppstreamPool();
  await pool.load();
  for (var component in pool.components) {
    var type = {
          AppstreamComponentType.unknown: 'unknown',
          AppstreamComponentType.generic: 'generic',
          AppstreamComponentType.desktopApplication: 'desktop-application',
          AppstreamComponentType.consoleApplication: 'console-application',
          AppstreamComponentType.webApplication: 'web-application',
          AppstreamComponentType.addon: 'addon',
          AppstreamComponentType.font: 'font',
          AppstreamComponentType.codec: 'codec',
          AppstreamComponentType.inputMethod: 'input-method',
          AppstreamComponentType.firmware: 'firmware',
          AppstreamComponentType.driver: 'driver',
          AppstreamComponentType.localization: 'localization',
          AppstreamComponentType.service: 'service',
          AppstreamComponentType.repository: 'repository',
          AppstreamComponentType.operatingSystem: 'operating-system',
          AppstreamComponentType.iconTheme: 'icon-theme',
          AppstreamComponentType.runtime: 'runtime',
        }[component.type] ??
        'unknown';
    var name = component.name['C'] ?? '';
    var summary = component.summary['C'] ?? '';
    String? homepage;
    for (var url in component.urls) {
      if (url.type == AppstreamUrlType.homepage) {
        homepage = url.url;
        break;
      }
    }

    print('---');
    print('Identifier: ${component.id} [$type]');
    print('Name: $name');
    print('Summary: $summary');
    if (component.package != null) {
      print('Package: ${component.package}');
    }
    if (homepage != null) {
      print('Homepage: $homepage');
    }
  }
}
