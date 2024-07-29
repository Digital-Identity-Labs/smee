Mix.install([{:smee, path: "."}])

Smee.Source.new("http://metadata.ukfederation.org.uk/ukfederation-metadata.xml")
|> Smee.fetch!()
|> Smee.Metadata.stream_entities()
|> Smee.Publish.write_aggregate(format: :disco, to: "output")