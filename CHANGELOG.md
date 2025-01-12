# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.5.1] - 2025-01-11

A bugfix release

### Fixes
- New `renater` namespace has been included - this appeared early in January 2025 and prevented parsing of 3 federations
  (there are possibly better long-term solutions than reactively adding new namespaces to Smee, hopefully this sort of
  problem can be avoided in the future with some smarter code in Smee)
- The Extract module could not list entity attribute types and values if more than one value was present, now it can. 
- The Security module began failing with the latest 1.3.6 `xmlsec1` *but only with the Mac Homebrew packaged version*. Using a hyphen
  pseudo-filename while piping XML stopped working, at least for me, when using Homebrew's package. This has been worked-around
  in Smee and should continue to work with all versions of `xmlsec1` ([GH issue](https://github.com/lsh123/xmlsec/issues/863))
- Exceptions that occur while parsing metadata should not now cause their own exceptions
- Problems caused by open file limits should now cause a warning about open file limits to be shown

## [0.5.0] - 2024-08-13

New, much bigger Publish module with new output formats and features.

### New Features
- Publish module has new output formats: CSV, DiscoFeed, markdown, THISS discovery, and two new formats
  for use with [Little Disco](https://github.com/Digital-Identity-Labs/little_disco)
- API has changed for Publish, but previous functions will continue to work for awhile, deprecated.
- Publish Formats can be written to disk directly as either single aggregated files or individual records
- :saml format now supports both aggregates and MDQ-style records
- Files can have MDQ/LocalDynamic style aliases generate automatically
- :index files can now have entity names included
- The :disco format should generate files compatible with the Shibboleth DiscoFeed
- The :thiss format should hopefully mimic the files used by THISS software such as Seamless Access
- The :markdown and :csv formats are suitable for publishing simple tables into documents
- :udisco is an experimental more efficient alternative to DiscoFeed, only used by [Little Disco](https://github.com/Digital-Identity-Labs/little_disco)
- :udest is also for [Little Disco](https://github.com/Digital-Identity-Labs/little_disco) and provides SP information

### Improvements
- Another XML namespace was discovered in the wild
- Recent Req versions will no longer complain about Accept header case
- Tests will now run on Github's CI service
- The Smee git repository now has a few ready-to-run example scripts
- Smee now has over 1100 tests

## [0.4.1] - 2024-17-03

A bug-fix released after testing with an updated collection of SmeeFeds test data: Smee is now tested with 66 federations. 

### Fixes
- XMLMunger can now cope with unusual namespaces better: this fixes an error when streaming entities from CAFE (and possibly others)
- Entity metadata IDs (rather then Entity IDs) have been fixed
- Non-compliant validUntil dates that lack a timezone offset will be processed as UTC now with a warning rather than an exception.
- Tags should now be unique (previously passing atoms and strings could lead to duplicates)
- Additional namespaces found in the wild during testing have been included
- Signatures are now properly removed (or at least, more often removed) before streaming
- Excess line endings are removed from pre-processed XML
- Streaming can cope with embedded EntityDescriptor groups

## [0.4.0] - 2024-02-05

### Breaking Changes
- XML in Metadata structs is now back to being the original metadata, with comments, signatures, etc.

### New Features
- Smee now uses its own cache directory for downloaded files, and that cache can be purged with `Smee.Sys.reset_cache/0`
- Sources, Metadata and Entity structs now have tags, and `tag/2` and `tags/1` functions to get and set them. Tags are inherited.
- Sources have optional `id` and `fedid` keys to help manage them in larger applications
- Source, Metadata and Entity structs are now truncated for `inspect`, omitting data and parsed XML, for easier debugging
- Source, Metadata and Entity structs can now be interpolated and printed in strings, showing a type and unique URI 
  (format may change in future releases)
- Source, Metadata and Entity structs now have `Jason`-compatible JSON export
- `Smee.Fetch.warm/2` will download a list of sources concurrently and warm the HTTP cache
- `Fetch.probe/1` will return last-modified and etag information from a Source
- You can add a Smee-optimised version of SweetXML's xpath sigil to your own projects with `Smee.Sigil`
- Entity now has functions to extract more information: `registration_authority/1`, `registered_at/1`, `categories/1`,
  `category_support/1` and `assurance/1`.
- New filters: `entity_category/3`, `entity_category_support/3`, `tag/3` and others
- Since `Smee.Metadata.xml/1` now returns the original XML, `Smee.Metadata.xml_processed/2` has been added to return
  tweaked versions of the XML. Presently only one processing option is available, `:strip`, which removes comments, etc.
- `Smee.Entity.id/1` and `Smee.Entity.transformed_id/1` as helpers for getting an entityID

### Improvements
- Speed improvements: processing Metadata into Entity structs is now twice as fast
- A few more metadata namespaces have been added to the default list
- Publishing aggregated metadata now has configurable validUntil dates. 
- `Fetch.fetch!/2` and `Fetch.local!/2` now have `Fetch.fetch/2` and `Fetch.local/2` equivalents.
- XML processing and searching has (hopefully) been optimised, some code was ported back from `SmeeView` for wider use.

### Fixes
- Should now work with OTP26 and Elixir 1.16.0 
- Hopefully compatible with recent versions of `xmlsec1`, which has changed its behaviour and commandline options.
- All known XML namespaces were being added to all metadata, now single entity XML should only include relevant namespaces.
- `validUntil` can now be set in XML when publishing single entity metadata
- XML in Metadata structs, and returned by `Smee.Metadata.xml/1`, is now identical to the input XML, which no longer 
  breaks verification with certificates. 

### Other Changes
- Namespaces in Metadata are now in alphabetical order, after the default namespace
- Updated dependencies, and hopefully loosened them for better integration compatibility with other apps 
- Published aggregates do not include a validUntil date by default now, it must be set.
- Temporarily includes a copy of [EasySSL](https://github.com/CaliDog/EasySSL)


## [0.3.0] - 2023-05-04

### Breaking Changes
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

[0.5.1]: https://github.com/Digital-Identity-Labs/smee/compare/0.5.0...0.5.1
[0.5.0]: https://github.com/Digital-Identity-Labs/smee/compare/0.4.1...0.5.0
[0.4.1]: https://github.com/Digital-Identity-Labs/smee/compare/0.4.0...0.4.1
[0.4.0]: https://github.com/Digital-Identity-Labs/smee/compare/0.3.0...0.4.0
[0.3.0]: https://github.com/Digital-Identity-Labs/smee/compare/0.2.0...0.3.0
[0.2.0]: https://github.com/Digital-Identity-Labs/smee/compare/0.1.0...0.2.0
[0.1.0]: https://github.com/Digital-Identity-Labs/smee/compare/releases/tag/0.1.0
