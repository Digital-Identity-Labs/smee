# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.4.0] - 24-01-

## Breaking Changes
- Smee is now not compatible with Windows, at least until this is supported by the Rambo package. We've had to chose between
  Windows support and easier use with modern Macs. If new versions of Rambo support Windows compilation again, Windows
  compatibility can return. !!! Might need to roll back this change

## New Features
- Smee now uses its own cache directory for downloaded files, and that cache can be purged with `Smee.Sys.reset_cache/0`
- Sources, Metadata and Entity structs now have tags, and `tag/2` and `tags/1` functions to get and set them. Tags are inherited.
- Sources have optional `id` and `fedid` keys to help manage them in larger applications
- Source, Metadata and Entity structs are now truncated for `inspect`, omitting data and parsed XML, for easier debugging
- Source, Metadata and Entity structs can now be interpolated and printed in strings, showing a type and unique URI 
  (format may change in future releases)
- `Smee.Fetch.warm/2` will download a list of sources concurrently and warm the HTTP cache

## Improvements
- A few more metadata namespaces have been added
- `Smee.Entity.id/1` and `Smee.Entity.transformed_id/1` as helpers for getting an entityID 
- Publishing aggregated metadata now has configurable validUntil dates. 
- `Fetch.fetch!/2` and `Fetch.local!/2` now have `Fetch.fetch/2` and `Fetch.local/2` equivalents.

## Fixes
- Should now work with OTP26 and Elixir 1.16.0 
- Hopefully compatible with recent versions of `xmlsec1`, which has changed its behaviour and commandline.  
- Rambo no longer needs to be specified as a compiler option and dependency on Macs.  !!! Might need to roll back this change
- All known XML namespaces were being added to all metadata, now single entity XML should only include relevant namespaces.
- `validUntil` can now be set in XML when publishing single entity metadata

## Other Changes
- Namespaces in metadata are now in alphabetical order, after the default namespace
- Updated dependencies, and hopefully loosened them for better integration compatibility with other apps 
- Published aggregates do not include a validUntil date by default now, it must be set.


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
