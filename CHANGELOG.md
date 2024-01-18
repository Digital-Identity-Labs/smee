# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.4.0] - 24-01-

## Breaking Changes
- Smee is now not compatible with Windows, at least until this is supported by the Rambo package. We've had to chose between
  Windows support and easier use with modern Macs. If new versions of Rambo support Windows compilation again, Windows
  compatibility can return.

## New Features
-

## Improvements
- A few more metadata namespaces have been added

## Fixes
- Should now work with OTP26 and Elixir 1.16.0 
- Hopefully compatible with recent versions of `xmlsec1`, which has changed its behaviour and commandline.  
- Rambo no longer needs to be specified as a compiler option and dependency on Macs.

## Other Changes
- Namespaces in metadata are now in alphabetical order, after the default namespace



## [0.3.0] - 2023-05-04

## Breaking Changes
- `Smee.Transform.strip_comments` has been removed because comments are now *always* removed from Metadata structs

- Metadata type is now set automatically
- All comments are removed from metadata when a Metadata struct is created


## [0.2.0] - 2023-04-15
XML storage and publishing bugfixes and small improvements, plus some breaking API changes

### Breaking Changes
* All functions in `Publish` have been renamed (they've lost their "to_", and sizes are "estimated_x_size")

### New Features
- Metadata and Entity modules have a `validate!/1` function to check XML schema compliance
- Metadata and Entity modules have `expired?/1` and `check_date!/1` functions
- A Mix task for installing the default backend requirements on Macs (via Homebrew) and Linux
- Code of Conduct document added
- Certificate fingerprints are converted to the correct format automatically (if they are valid sha1 hashes at least)

## Fixes
- Entity XML is now stored with namespaces and processed with xmerl in a namespace-aware way. This fixes problems with
  other libraries (specifically SmeeView) that were using xpath and not getting consistent results.
- Backends no longer output messages to stderr on terminal (tests look **much**) nicer now
- Basic documentation for Security module
- Published XML aggregates are now smaller and tidier
- EntityDescriptor end tags should now match the start tags

### Changed
- Tweaks to Readme.md
- Refactored XML pre-processing code, added XmlMunger module
- Moved private XML munging code from Publish and Metadata to XmlMunger to make it testable
- Optional federation-compatibility tests (run with `mix test --only compatibility`)
- EntitiesDescriptor and EntityDescriptor are now flat, one-line tags
- More namespaces are available



## [0.1.0] - 2023-04-11
Initial release

[0.2.0]: https://github.com/Digital-Identity-Labs/smee/compare/0.1.0...0.2.0
[0.1.0]: https://github.com/Digital-Identity-Labs/smee/compare/releases/tag/0.1.0
