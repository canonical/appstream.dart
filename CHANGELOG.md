# Changelog

## 0.2.7

* Read and parse XML/YAML files using isolates to avoid blocking the main event loop.

## 0.2.6

* Filter out null keywords.
* Fix the simple code example in the README.
* Fix a typo in error messages (s/Invaid/Invalid/g).
* Filter out invalid YAML documents (because of duplicate mapping keys).

## 0.2.5

* Update xml dependency to version 6.1.x.
* Update lints package to version 2.

## 0.2.4

* Only list as supporting Linux.

## 0.2.3

* Handle empty URLs.
* Handle versions being encoded as Yaml doubles.

## 0.2.2

* Correctly parse release URLs.
* Package is optional for components.
* Fix inputmethod type name incorrect.

## 0.2.1

* Add missing documentation on AppstreamFirmwareType and AppstreamDBusType.
* Update package description.

## 0.2.0

* Use enums in provides.
* Decode more YAML provides.
* Fix parsing of developer name.
* Add documentation.

## 0.1.2

* Fix error decoding YAML collection priority.
* Fix XML collection version/origin attributes.
* Decode XML collection architecture.

## 0.1.1

* Load releases, languages and content ratings.

## 0.1.0

* Initial release
