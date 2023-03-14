# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.2.0] - 
XML storage and publishing bugfixes and small improvements, plus some breaking API changes

### Breaking Changes
* All functions in `Publish` have been renamed (they've lost their "to_", and sizes are "estimated_x_size")

### New Features
- A Mix task for installing the default backend requirements on Macs (via Homebrew) and Linux
- Code of Conduct document added

## Fixes
- Entity XML is now stored with namespaces and processed with xmerl in a namespace-aware way. This fixes problems with
  other libraries (specifically SmeeView) that were using xpath and not getting consistent results.
- Backends no longer output messages to stderr on terminal (tests look **much**) nicer now
- Basic documentation for Security module
- Published XML aggregates are now smaller and tidier

### Changed
- Tweaks to Readme.md
- Refactored XML pre-processing code, added XmlMunger module
- Moved private XML munging code from Publish and Metadata to XmlMunger to make it testable



## [0.1.0] - 2020-04-11
Initial release

[0.2.0]: https://github.com/Digital-Identity-Labs/smee/compare/0.1.0...0.2.0
[0.1.0]: https://github.com/Digital-Identity-Labs/smee/compare/releases/tag/0.1.0
