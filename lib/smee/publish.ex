defmodule Smee.Publish do

  @moduledoc """
  Publish exports streams or lists of entity structs into various formats.

  At present the output formats are SAML XML (individual and collections) and simple index text files. Formats can be
  output as binary strings or streamed. Streamed output can be useful for web services, allowing gradual downloads generated
  on-the-fly with no need to render a very large document in advance.

  Options:
  * `valid_until` - pass a DateTime to set the validUntil attribute for the entity metadata. Alternatively, an integer can be
    passed to request a validity of n days, or "default" and "auto" to use the default validity period.
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

  def stream(entities, options \\ []) do
    apply(select_backend(options), :stream, [entities, options])
  end

  def text(entities, options \\ []) do
    apply(select_backend(options), :text, [entities, options])
  end

  def file(entities, options \\ []) do
    apply(select_backend(options), :file, [entities, options])
  end

  def size(entities, options \\ []) do
    apply(select_backend(options), :size, [entities, options])
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
    case options[:type] do
      :metadata -> SamlXml
      :disco -> Disco
      :udisco -> Udisco
      :udest -> Udest
      :thiss -> Thiss
      :index -> Index
      :markdown -> Markdown
      :csv -> Csv
      nil -> SamlXml
      _ -> raise "Unknown publishing format '#{options[:type]}'"
    end
  end

end
