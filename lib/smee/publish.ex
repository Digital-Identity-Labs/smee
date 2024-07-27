defmodule Smee.Publish do

  @moduledoc """
  Publish exports streams or lists of entity structs into various formats.

  Formats can be output as binary strings or streamed. Streamed output can be useful for web services, allowing gradual downloads generated
  on-the-fly with no need to render a very large document in advance.

  Options:
    * `:format` - The publishing format - defaults to `:saml` for SAML metadata. See below for other options
    * `:valid_until` - pass a DateTime to set the validUntil attribute for the entity metadata. Alternatively, an integer can be
    passed to request a validity of n days, or "default" and "auto" to use the default validity period.
    * `:wrap` - If set to true (the default) published streams and text data will be valid complete. When false, the top
    and bottom of the file will be missing, so it can be easily embedded or concatenated with other data
    * `:aggregate` - when true (the default for streams) streams will be published as aggregated data, or a single file. When false,
      streams will be returned as a list of individual records or files. When Individual entities are passed, this defaults
      to false.

  Publishing formats:
    *`:csv` - a brief CSV summary of the entities
    *`:disco` - Shibboleth DiscoFeed format JSON, used by the Embedded Discovery Service and others
    *`:index` - a plain text format containing entity ID and an optional name on each line
    *`:markdown` - a simple Markdown table summarising the entities
    *`:saml` - SAML2 metadata
    *`:thiss` - Entity information in the JSON format used by THISS software such as the Seamless Access discover service
    *`:udest` - A compact JSON format for SPs, used by Little Disco discovery service
    *`:udisco` - An efficient JSON format used by Little Disco as an alternative to `:disco`/DiscoFeed



  """

  alias Smee.Entity
  alias Smee.XmlMunger
  alias Smee.Publish.Disco
  alias Smee.Publish.Udisco
  alias Smee.Publish.Udest
  alias Smee.Publish.Thiss
  alias Smee.Publish.Index
  alias Smee.Publish.Markdown
  alias Smee.Publish.Csv
  alias Smee.Publish.SamlXml

  @spec types() :: list(atom())
  def types() do
    [
    :csv,
    :disco,
    :index,
    :markdown,
    :saml,
    :thiss,
    :udest,
    :udisco
    ]
  end

  def extract(entity, options \\ []) do
    options = Keyword.merge([lang: "en"], options)
              |> Keywords.take([:lang, :valid_until, :format])
    apply(select_backend(options), :extract, [entity, options])
  end

  def stream(entities, options \\ []) do
    options = Keyword.merge([lang: "en", wrap: true], options)
              |> Keywords.take([:lang, :valid_until, :wrap, :format])
    apply(select_backend(options), :stream, [entities, options])
  end

  def text(entities, options \\ []) do
    options = Keyword.merge([lang: "en"], options)
              |> Keywords.take([:lang, :valid_until, :format])
    apply(select_backend(options), :text, [entities, options])
  end

  def data(entities, options \\ []) do
    options = Keyword.merge([lang: "en"], options)
              |> Keywords.take([:lang, :valid_until, :format])
    apply(select_backend(options), :text, [entities, options])
  end

  def write(entities, options \\ []) do
    options = Keyword.merge([lang: "en", dir: "publish", naming: :default ], options)
              |> Keywords.take([:lang, :valid_until, :dir, :naming, :format])
    apply(select_backend(options), :write, [entities, options])
  end

  def est_length(entities, options \\ []) do
    options = Keyword.merge([lang: "en"], options)
              |> Keywords.take([:lang, :valid_until, :format])
    apply(select_backend(options), :est_length, [entities, options])
  end

  ############# Deprecated ################

  @doc """
  Returns a streamed index file, a plain text list of entity IDs.

    > #### Soft Deprecation {: .warning}
    >
    > Will be later deprecated in favor of `stream/2`.

  """
  @deprecated "Use Publish.stream/2 instead"
  @spec index_stream(entities :: Enumerable.t(), options :: keyword()) :: Enumerable.t()
  def index_stream(entities, options \\ []) do
    Index.stream(entities, options)
  end

  @doc """
  Returns the estimated size of a streamed index file without generating it in advance.
  """
  @deprecated "Use Publish.estimated_size/2 instead"
  @spec estimate_index_size(entities :: Enumerable.t(), options :: keyword()) :: integer()
  def estimate_index_size(entities, options \\ []) do
    Index.estimate_size(entities, options)
  end

  @doc """
  Returns an index text document
  """
  @deprecated "Use Publish.text/2 instead"
  @spec index(entities :: Enumerable.t(), options :: keyword()) :: binary()
  def index(entities, options \\ []) do
    Index.text(entities, options)
  end

  @doc """
  Returns a streamed SAML metadata XML file
  """
  @deprecated "Use Publish.stream/2 instead"
  @spec xml_stream(entities :: Entity.t() | Enumerable.t(), options :: keyword()) :: Enumerable.t()
  def xml_stream(entities, options \\ []) do
    Aggregate.stream(entities, options)
  end



  @doc """
  Returns the estimated size of a streamed SAML metadata XML file without generating it in advance.
  """
  @deprecated "Use Publish.estimated_size/2 instead"
  @spec estimate_xml_size(entities :: Enumerable.t(), options :: keyword()) :: integer()
  def estimate_xml_size(entities, options \\ []) do
    Aggregate.estimate_size(entities, options)
  end

  @doc """
  Returns a SAML metadata XML file, potentially very large.
  """
  @deprecated "Use Publish.text/2 instead"
  @spec xml(entities :: Enumerable.t(), options :: keyword()) :: binary()
  def xml(entities, options \\ []) do
    Aggregate.text(entities, options)
  end

  ################################################################################

  defp select_backend(options) do
    case options[:format] do
      :csv -> Csv
      :disco -> Disco
      :index -> Index
      :markdown -> Markdown
      :metadata -> SamlXml
      :saml -> SamlXml
      :thiss -> Thiss
      :udest -> Udest
      :udisco -> Udisco
      nil -> SamlXml
      _ -> raise "Unknown publishing format '#{options[:format]}'"
    end
  end

end
