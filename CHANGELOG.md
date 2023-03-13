# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.2.0] - 
XML storage and publishing improvements

### Breaking Changes


### New
- Code of Conduct document added

## Fixes
- Entity XML is now stored with namespaces and processed with xmerl in a namespace-aware way. This fixes problems with
  other libraries (specifically SmeeView) that were using xpath and not getting consistent results.

### Changed
- Tweaks to Readme.md
- Refactored XML pre-processing code, added XmlMunger module
- Moved private XML munging code from Publish and Metadata to XmlMunger to make it testable

### MOVE
- 


## [0.1.0] - 2020-04-11
Initial release

[0.2.0]: https://github.com/Digital-Identity-Labs/smee/compare/0.1.0...0.2.0
[0.1.0]: https://github.com/Digital-Identity-Labs/smee/compare/releases/tag/0.1.0
