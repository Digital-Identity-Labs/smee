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

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at <https://hexdocs.pm/Smee>.

```elixir

Smee.fetch(url)
Smee.safe_fetch(url)
Smee.split()

Smee.Source
Smee.Metadata
Smee.Entity

Smee.Fetch.remote(client, url, only: [a,b,c], except: [c])
Smee.Fetch.file(filename)
Smee.Fetch.directory(filename)
Smee.Fetch.source(source)

Smee.Verify.xml(metadata)
Smee.Verify.signature(metadata, certs)
Smee.Verify.casual(metadata, certs)

Smee.Metadata.info(metadata) # ??

Smee.Process.stream_xml(metadata)
Smee.Process.stream_entities(metadata)

Source.new(client, url)
|> Fetch.source()
|> Verify.signature()
|> Process.stream_entities()
|> Enum.map(&X.thing)

```

