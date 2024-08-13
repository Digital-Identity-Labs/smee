#!/usr/bin/env elixir
Mix.install([{:smee, ">= 0.5.0"}])

## Create a DiscoFeed file from a full federation aggregate
Smee.Source.new("http://metadata.ukfederation.org.uk/ukfederation-metadata.xml")
|> Smee.fetch!()
|> Smee.Metadata.stream_entities()
|> Smee.Publish.write_aggregate(format: :disco, to: "output")