# Smee

**TODO: Add description**

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

* https://shibboleth.atlassian.net/wiki/spaces/IDP4/pages/2986475557/MetadataDrivenConfigurationExamples
* https://shibboleth.atlassian.net/wiki/spaces/IDP4/pages/1265631679/MetadataDrivenConfiguration

* https://github.com/trscavo/saml-library/tree/master/lib
* https://github.com/johnhamelink/xslt
* https://swamid.se/swamid-metadata.git/tree/xslt
* https://github.com/ukf/ukf-meta

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at <https://hexdocs.pm/Smee>.

```elixir



```

## Extra things needed for mDeco use

* Wrap metadata with namespace declarations
* Normalise namespaces so they are consistent
* Maaaaybeeee sign metadata
* Purge all or some Entity Attributes
* Insert new Entity Attributes
* Join metadata fragments together

