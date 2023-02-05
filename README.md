# Smee

`Smee` is a pragmatic library for handling SAML metadata.

Smee started life as an sprawling mess of code used over five years in an internal application to download and process
SAML metadata. It's now been extracted, restructured and made a **little** less messy, with the aim of reusing it in other 
projects.

[![Hex pm](http://img.shields.io/hexpm/v/smee.svg?style=flat)](https://hex.pm/packages/smee)
[![API Docs](https://img.shields.io/badge/api-docs-yellow.svg?style=flat)](http://hexdocs.pm/smee/)
![Github Elixir CI](https://github.com/Digital-Identity-Labs/smee/workflows/Elixir%20CI/badge.svg)
[![License](https://img.shields.io/hexpm/l/smee.svg)](LICENSE)


## Features

The top level Smee module contains simplified, top level functions better suited to simpler scripts. Other modules in
Smee contain more tools for handling SAML metadata, such as:

* `Smee.Source` - define sources of metadata
* `Smee.Metadata` - functions for handling metadata aggregates
* `Smee.Entity` - individual SAML entity definitions
* `Smee.Extract` - processing metadata to extract information
* `Smee.Fetch` - downloading metadata sources
* `Smee.MDQ` - functions for MDQ clients (and emulating MDQ clients)
* `Smee.Filter` - filtering streams of entity records
* `Smee.Transform` - processing and editing entity XML
* `Smee.Publish` - Formatting and outputting metadata in various formats

## Examples


## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `Smee` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:Smee, "~> 0.1.0"}
  ]
end
```
Smee does not do all processing itself, using Elixir - it sometimes cheats (OK, it often cheats) by sending data to
external programs for processing. At the moment it requires:

* `xmlsec1`
* `xmllint`
* `xsltproc`


## Purpose


## Pragmatic?

## References

* https://shibboleth.atlassian.net/wiki/spaces/SC/pages/1912406916/OAuthRPMetadataProfile
* https://shibboleth.atlassian.net/wiki/spaces/SC/pages/1836417024/ADFSMetadataProfile
* https://shibboleth.atlassian.net/wiki/spaces/SC/pages/1879344655/CASMetadataProfile

* https://shibboleth.atlassian.net/wiki/spaces/IDP4/pages/2986475557/MetadataDrivenConfigurationExamples
* https://shibboleth.atlassian.net/wiki/spaces/IDP4/pages/1265631679/MetadataDrivenConfiguration

* https://github.com/trscavo/saml-library/tree/master/lib
* https://github.com/johnhamelink/xslt
* https://swamid.se/swamid-metadata.git/tree/xslt
* https://github.com/ukf/ukf-meta

## Documentation

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at <https://hexdocs.pm/Smee>.

## Copyright and License

Copyright (c) 2023 Digital Identity Ltd, UK

Smee is Apache 2.0 licensed.

## Disclaimer
Smee is not endorsed by The Shibboleth Foundation or any of the NREN's that may have had their XSLT borrowed.