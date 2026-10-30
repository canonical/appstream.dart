import 'package:appstream/appstream.dart';
import 'package:appstream/src/codec.dart';
import 'package:test/test.dart';

class _UnknownIcon extends AppstreamIcon {
  const _UnknownIcon();
}

class _UnknownProvides extends AppstreamProvides {
  const _UnknownProvides();
}

class _UnknownLaunchable extends AppstreamLaunchable {
  const _UnknownLaunchable();
}

List<Object?> fieldsOf(AppstreamComponent component) => [
      component.id,
      component.type,
      component.package,
      component.name,
      component.summary,
      component.description,
      component.developerName,
      component.projectLicense,
      component.projectGroup,
      component.icons,
      component.urls,
      component.categories,
      component.keywords,
      component.screenshots,
      component.compulsoryForDesktops,
      component.releases,
      component.provides,
      component.launchables,
      component.languages,
      component.bundles,
      component.custom,
      component.contentRatings,
    ];

void expectSame(AppstreamComponent actual, AppstreamComponent expected) {
  expect(fieldsOf(actual), equals(fieldsOf(expected)));
  // equals() ignores the order of map keys, the printed form does not.
  expect('${fieldsOf(actual)}', equals('${fieldsOf(expected)}'));
}

AppstreamComponent roundTrip(AppstreamComponent component) =>
    EncodedComponents.encode([component])[0];

AppstreamComponent minimal({
  String id = 'com.example.Minimal',
  AppstreamComponentType type = AppstreamComponentType.unknown,
  Map<String, String> description = const {},
  List<AppstreamIcon> icons = const [],
  List<AppstreamProvides> provides = const [],
  List<AppstreamLaunchable> launchables = const [],
  List<AppstreamLanguage> languages = const [],
  List<AppstreamRelease> releases = const [],
  List<AppstreamScreenshot> screenshots = const [],
}) =>
    AppstreamComponent(
      id: id,
      type: type,
      package: null,
      name: const {},
      summary: const {},
      description: description,
      icons: icons,
      provides: provides,
      launchables: launchables,
      languages: languages,
      releases: releases,
      screenshots: screenshots,
    );

void main() {
  final everything = AppstreamComponent(
    id: 'org.example.Everything',
    type: AppstreamComponentType.desktopApplication,
    package: 'everything',
    name: const {'C': 'Everything', 'de': 'Alles', 'zh_CN': '一切 🌏'},
    summary: const {'C': 'Has every field', 'fr_CA': 'Chaque champ'},
    description: const {'C': '<p>Line one\nLine two \u0000 end</p>'},
    developerName: const {'C': 'Example Org', 'de': 'Beispiel e. V.'},
    projectLicense: 'GPL-3.0-or-later',
    projectGroup: 'GNOME',
    icons: const [
      AppstreamStockIcon('everything'),
      AppstreamCachedIcon('everything.png', width: 64, height: 64),
      AppstreamCachedIcon('plain.png'),
      AppstreamLocalIcon('/usr/share/icons/everything.svg', width: 128),
      AppstreamRemoteIcon('https://example.com/icon.png', height: 48),
    ],
    urls: [
      for (final type in AppstreamUrlType.values)
        AppstreamUrl('https://example.com/${type.name}', type: type),
    ],
    categories: const ['Game', 'ArcadeGame'],
    keywords: const {
      'C': ['one', 'two'],
      'de': ['eins'],
      'ja': [],
    },
    screenshots: const [
      AppstreamScreenshot(
        images: [
          AppstreamImage(
            type: AppstreamImageType.source,
            url: 'https://example.com/big.png',
            width: 1920,
            height: 1080,
            lang: 'en',
          ),
          AppstreamImage(
            type: AppstreamImageType.thumbnail,
            url: 'https://example.com/small.png',
          ),
        ],
        caption: {'C': 'Main window', 'de': 'Hauptfenster'},
        isDefault: true,
      ),
      AppstreamScreenshot(),
    ],
    compulsoryForDesktops: const ['GNOME', 'Unity'],
    releases: [
      AppstreamRelease(
        version: '1.0',
        date: DateTime.utc(2024, 2, 29, 12, 30, 45, 123, 456),
        type: AppstreamReleaseType.snapshot,
        urgency: AppstreamReleaseUrgency.critical,
        description: const {'C': '<p>Fixes</p>', 'de': '<p>Korrekturen</p>'},
        url: 'https://example.com/1.0',
        issues: const [
          AppstreamIssue(
            'CVE-2024-1',
            type: AppstreamIssueType.cve,
            url: 'https://example.com/cve',
          ),
          AppstreamIssue('42'),
        ],
      ),
      AppstreamRelease(
        date: DateTime(2020, 5, 6, 7, 8),
        type: AppstreamReleaseType.development,
        urgency: AppstreamReleaseUrgency.low,
      ),
      const AppstreamRelease(),
    ],
    provides: const [
      AppstreamProvidesMediatype('text/plain'),
      AppstreamProvidesLibrary('libeverything.so.1'),
      AppstreamProvidesBinary('everything'),
      AppstreamProvidesFont('Everything Sans'),
      AppstreamProvidesModalias('usb:v1234p5678d*'),
      AppstreamProvidesFirmware(AppstreamFirmwareType.flashed, 'abc-123'),
      AppstreamProvidesFirmware(AppstreamFirmwareType.runtime, 'def-456'),
      AppstreamProvidesPython2('everything2'),
      AppstreamProvidesPython3('everything3'),
      AppstreamProvidesDBus(AppstreamDBusType.system, 'org.example.Everything'),
      AppstreamProvidesId('org.example.Old'),
    ],
    launchables: const [
      AppstreamLaunchableDesktopId('everything.desktop'),
      AppstreamLaunchableService('everything.service'),
      AppstreamLaunchableCockpitManifest('everything'),
      AppstreamLaunchableUrl('https://example.com/app'),
    ],
    languages: const [
      AppstreamLanguage('de', percentage: 100),
      AppstreamLanguage('fr'),
      AppstreamLanguage('xx', percentage: -5),
    ],
    bundles: [
      for (final type in AppstreamBundleType.values)
        AppstreamBundle('everything-${type.name}', type: type),
    ],
    custom: const [
      {'a': 'b'},
      {'c': 'd'},
    ],
    contentRatings: const {
      'oars-1.0': {
        'violence-fantasy': AppstreamContentRating.intense,
        'drugs-alcohol': AppstreamContentRating.moderate,
        'language-humor': AppstreamContentRating.mild,
        'sex-nudity': AppstreamContentRating.none,
      },
      'oars-1.1': {},
    },
  );

  test('codec - a component with every field survives', () {
    expectSame(roundTrip(everything), everything);
  });

  test('codec - a component with nothing but the required fields survives', () {
    final component = minimal();
    expectSame(roundTrip(component), component);
  });

  for (final type in AppstreamComponentType.values) {
    test('codec - component type ${type.name} survives', () {
      final component = minimal(type: type);
      expect(roundTrip(component).type, equals(type));
    });
  }

  test('codec - text of every kind survives', () {
    for (final text in [
      '',
      'ascii',
      'ünïcödé',
      '日本語',
      '🌏 and 👩‍👩‍👧‍👦',
      'tab\tnewline\ncarriage\r\u0000nul',
      // Long enough to need a multi-byte length and to grow the buffer.
      'é' * 100000,
    ]) {
      final component = minimal(description: {'C': text});
      expect(roundTrip(component).description, equals({'C': text}));
    }
  });

  test('codec - integers of every size survive', () {
    const widths = [
      0,
      1,
      -1,
      63,
      64,
      -64,
      -65,
      127,
      128,
      1 << 40,
      -(1 << 40),
      9223372036854775807,
      -9223372036854775808,
    ];
    final component = minimal(
      icons: [
        for (final width in widths) AppstreamCachedIcon('a', width: width),
      ],
      languages: [
        for (final width in widths) AppstreamLanguage('a', percentage: width),
      ],
    );
    expectSame(roundTrip(component), component);
  });

  test('codec - dates keep their instant and whether they are UTC', () {
    final dates = [
      DateTime.utc(1970),
      DateTime.utc(1969, 12, 31, 23, 59, 59, 999, 999),
      DateTime.utc(2024, 2, 29, 12, 30, 45, 123, 456),
      DateTime(2020, 5, 6, 7, 8),
      DateTime.fromMicrosecondsSinceEpoch(8640000000000000000, isUtc: true),
      DateTime.fromMicrosecondsSinceEpoch(-8640000000000000000, isUtc: true),
    ];
    final component = minimal(
      releases: [for (final date in dates) AppstreamRelease(date: date)],
    );
    final decoded = roundTrip(component).releases;
    expect(
      decoded.map((release) => release.date),
      equals(dates),
    );
    expect(
      decoded.map((release) => release.date!.isUtc),
      equals(dates.map((date) => date.isUtc)),
    );
  });

  test('codec - every enum value survives', () {
    final component = minimal(
      releases: [
        for (final type in AppstreamReleaseType.values)
          for (final urgency in AppstreamReleaseUrgency.values)
            AppstreamRelease(
              type: type,
              urgency: urgency,
              issues: [
                for (final issueType in AppstreamIssueType.values)
                  AppstreamIssue('id', type: issueType),
              ],
            ),
      ],
      provides: [
        for (final type in AppstreamFirmwareType.values)
          AppstreamProvidesFirmware(type, 'name'),
        for (final type in AppstreamDBusType.values)
          AppstreamProvidesDBus(type, 'name'),
      ],
      screenshots: [
        AppstreamScreenshot(
          images: [
            for (final type in AppstreamImageType.values)
              AppstreamImage(type: type, url: 'https://example.com'),
          ],
        ),
      ],
    );
    expectSame(roundTrip(component), component);
  });

  test('codec - components are read back in order, at random', () {
    final components = [
      for (var i = 0; i < 50; i++)
        i.isEven ? minimal(id: 'com.example.App$i') : everything,
    ];
    final encoded = EncodedComponents.encode(components);
    expect(encoded.length, equals(components.length));
    for (final i in [for (var i = 49; i >= 0; i--) i]) {
      expectSame(encoded[i], components[i]);
    }
  });

  test('codec - nothing encodes to nothing', () {
    final encoded = EncodedComponents.encode(const []);
    expect(encoded.length, equals(0));
    expect(() => encoded[0], throwsRangeError);
  });

  test('codec - each read gives a new object', () {
    final encoded = EncodedComponents.encode([everything]);
    expect(identical(encoded[0], encoded[0]), isFalse);
  });

  test('codec - an icon type it does not know is refused', () {
    final component = minimal(icons: const [_UnknownIcon()]);
    expect(() => EncodedComponents.encode([component]), throwsArgumentError);
  });

  test('codec - a provides type it does not know is refused', () {
    final component = minimal(provides: const [_UnknownProvides()]);
    expect(() => EncodedComponents.encode([component]), throwsArgumentError);
  });

  test('codec - a launchable type it does not know is refused', () {
    final component = minimal(launchables: const [_UnknownLaunchable()]);
    expect(() => EncodedComponents.encode([component]), throwsArgumentError);
  });
}
