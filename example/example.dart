// ignore_for_file: avoid_print

import 'package:appstream/appstream.dart';

void main() async {
  final pool = AppstreamPool();
  await pool.load();
  for (final component in pool.components) {
    final type = {
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
    final name = component.name['C'] ?? '';
    final summary = component.summary['C'] ?? '';
    String? homepage;
    for (final url in component.urls) {
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
