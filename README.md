# Smee

`Smee` is a pragmatic library for handling SAML metadata with Elixir, Erlang or any other BEAM language.

Smee started life as an sprawling mess of code used over five years in an internal application to download and process
SAML metadata. It's now been extracted, restructured and made a **little** less messy, with the aim of reusing it in other 
projects. Smee can be used within applications or in simpler scripts for processing metadata.

[![Hex pm](http://img.shields.io/hexpm/v/smee.svg?style=flat)](https://hex.pm/packages/smee)
[![API Docs](https://img.shields.io/badge/api-docs-yellow.svg?style=flat)](http://hexdocs.pm/smee/)
![Github Elixir CI](https://github.com/Digital-Identity-Labs/smee/workflows/Elixir%20CI/badge.svg)

[![Run in Livebook](https://livebook.dev/badge/v1/blue.svg)](https://livebook.dev/run?url=https%3A%2F%2Fraw.githubusercontent.com%2FDigital-Identity-Labs%2Fsmee%2Fmain%2Fsmee_notebook.livemd)

## Features

* Download remote SAML metadata or load local files, with effective caching
* Manage and compare metadata files and individual entity metadata 
* MDQ API (which can also emulate MDQ style lookups with aggregate files)
* A focus on streaming with reliable and surprisingly low memory usage
* Filter entity streams by various criteria
* Validate XML signatures, automatically download and confirm signing certificates
* Transform metadata using XSLT, or extract data
* Access XML using Erlang's Xmerl library (sweetened by SweetXML)
* Recombine entity streams into aggregates or other data formats
* Can be used with applications or in simple .exs scripts

The top level `Smee` module contains simplified, top level functions better suited to simpler scripts. Other modules in
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
* `Smee.Stats` - Simple stats for entity streams
* `Smee.Sigils` - An ~x sigil for XPaths optimized for use with SAML

## Extensions and Extras

* [SmeeFeds](https://github.com/Digital-Identity-Labs/smee_feds) - a federation management extension for use in
  research, testing and development. SmeeFeds has a built-in list of many education and research federations.

## Examples

### Getting entity details from an MDQ service

```elixir
alias Smee.MDQ

cern_idp = 
  MDQ.source("http://mdq.ukfederation.org.uk/")
  |> MDQ.lookup!("https://cern.ch/login")

```

### Downloading and streaming a metadata aggregate to output a list of all IdP entityIDs

```elixir
alias Smee.{Source, Fetch, Filter, Metadata}

"http://metadata.ukfederation.org.uk/ukfederation-metadata.xml"
|> Source.new()
|> Fetch.remote!()
|> Metadata.stream_entities()
|> Filter.idp()
|> Stream.map(fn e -> e.uri end)
|> Enum.to_list()

```

### Create an aggregate that only contains SPs with SIRTFI, that were registered over the previous 12 months 

```elixir
alias Smee.{Source, Fetch, Filter, Metadata, Publish}

"http://metadata.ukfederation.org.uk/ukfederation-metadata.xml"
|> Source.new()
|> Fetch.remote!()
|> Metadata.stream_entities()
|> Filter.days(365)
|> Filter.sp()
|> Filter.assurance("https://refeds.org/sirtfi")
|> Publish.xml()

```
### Munge XML with XSLT

```elixir
alias Smee.{Source, Fetch, Transform, Metadata}

## Using a builtin function

new_xml = Source.new("adfs.xml")
|> Fetch.local!()
|> Transform.decruft_sp!()
|> Metadata.xml()

File.save!("adfs_new.xml", new_xml)

## Or any XSLT stylesheet

{:ok, updated_metadata} = Transform.transform(metadata, stylesheet, [exampleParam: "example value"])

```

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `Smee` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:Smee, "~> 0.4.1"}
  ]
end
```

### Backend tools

**Please note:** Smee does not do all processing itself using Elixir - it sometimes cheats (OK, it often cheats) by sending data to
external programs for processing. At the moment it requires the following commandline utilities:

* `xmlsec1`
* `xmllint`
* `xsltproc`

Smee now includes a Mix task to install the default backend software - just run:

`mix deps.smee`

(Currently only tested on Macs with Homebrew, but it *should* also work on Debian, Ubuntu, Red Hat and Alpine Linux)

A future version of Smee will support alternative sets of backends.

### Rambo and Rust

Smee uses an Elixir library called [Rambo](https://hex.pm/packages/rambo) to run external utilities like xsltproc. Rambo 
relies on a small compiled shim that is provided pre-compiled for various architectures or automatically built during installation.

- If your system does not match any of the supplied binary shims, you will need to have a rust compiler installed so Rambo
  can build the shim itself. 
- Version 0.3.4 of Rambo has an additional problem: it does not ship with a precompiled binary for M1 Macs, *and it also does
  not automatically build one*. Smee works around that with an explicit compile step in `mix.exs`, but it prevent Smee from
  being used in Elixir .exs scripts on M1 Macs unless you copy the compiled shim from Smee into your script's build directory.
  Hopefully this will be fixed in later versions of Rambo. 
- If you are using a modern M1/M2/M3 Mac you may need to explicitly include Rambo as a dependency in your project.

## Uses

Metadata Database: Smee was extracted from an application that downloads, processes and stores SAML metadata in a database for access 
with an API. The original code had become rather messy and was very difficult to test - hopefully Smee will be an 
improvement and will be used to replace the original code. Smee doesn't currently handle digestion and storage.

MDQ Service: We've made a streaming MDQ service using Smee that should soon be available 

Reports: We've generated reports for clients using Smee

## Possible Alternatives

These aren't quite the same but are mature, widely used projects that are a lot more stable than Smee. In many cases you 
should definitely use these instead of Smee.

* [SAML Library by Tom Scavo](https://github.com/trscavo/saml-library/) A collection of Bash and XSLT scripts 
* [PyFF](https://github.com/IdentityPython/pyFF) A metadata pipeline and server using Python and YAML
* [Shibboleth Metadata Aggregator](https://shibboleth.atlassian.net/wiki/spaces/MA1/overview) Widely used Java metadata pipeline

## References

### SAML Metadata
* [Wikipedia's summary](https://en.wikipedia.org/wiki/SAML_2.0)

### MDQ 
* [UK Federation Explains MDQ](https://www.ukfederation.org.uk/content/Documents/MDQ)

### Unusual types of SAML metadata
* [Oauth/OIDC](https://shibboleth.atlassian.net/wiki/spaces/SC/pages/1912406916/OAuthRPMetadataProfile)
* [ADFS does it's own thing](https://shibboleth.atlassian.net/wiki/spaces/SC/pages/1836417024/ADFSMetadataProfile)
* [CAS!](https://shibboleth.atlassian.net/wiki/spaces/SC/pages/1879344655/CASMetadataProfile)

## Contributors and Sources

Various Github repositories have been plundered in a search for XSLT stylesheets, in particular:

* [SAML Library by Tom Scavo](https://github.com/trscavo/saml-library/)
* [SWAMID Federation](https://swamid.se/swamid-metadata.git/tree/xslt)
* [UK Access Management Federation's metadata processing pipeline](https://github.com/ukf/ukf-meta)

The use of the Apache2 license in the above projects led to the Apache2 license for Smee.

Other sources and inspirations:

* [The XSLT package for Elixir](https://github.com/johnhamelink/xslt)

Smee temporarily includes a copy of [EasySSL](https://github.com/CaliDog/EasySSL) (MIT Licensed) that was required to
fix an Erlang 26 compatibility issue. This will revert to a normal dependency when an update is released.

## Documentation

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at <https://hexdocs.pm/smee>.

## Contributing

You can request new features by creating an [issue](https://github.com/Digital-Identity-Labs/smee/issues),
or submit a [pull request](https://github.com/Digital-Identity-Labs/smee/pulls) with your contribution.

If you are comfortable working with Python but Smee's Elixir code is unfamiliar then this blog post may help: 
[Elixir For Humans Who Know Python](https://hibox.live/elixir-for-humans-who-know-python)

## Copyright and License

Copyright (c) 2023, 2024 Digital Identity Ltd, UK

Smee is Apache 2.0 licensed.

## Disclaimer
Smee is not endorsed by The Shibboleth Foundation or any of the NREN's that may have had their XSLT borrowed.
The API will definitely change considerably in the first few releases after 0.1.0 - it is not stable!
