defmodule Smee.Publish.LegacyCompatibility do


  defmacro __using__(_opts) do
    quote do

      @moduledoc false


      alias Smee.Entity
      alias Smee.Publish
      alias Smee.Publish.Disco
      alias Smee.Publish.Udisco
      alias Smee.Publish.Udest
      alias Smee.Publish.Thiss
      alias Smee.Publish.Index
      alias Smee.Publish.Markdown
      alias Smee.Publish.Csv
      alias Smee.Publish.SamlXml

      ############# Deprecated ################

      @doc false
      @deprecated "Use Publish.stream/2 instead"
      @spec index_stream(entities :: Enumerable.t(), options :: keyword()) :: Enumerable.t()
      def index_stream(entities, options \\ []) do
        Index.aggregate_stream(entities, options)
      end

      @doc false
      @deprecated "Use Publish.eslength/2 instead"
      @spec estimate_index_size(entities :: Enumerable.t(), options :: keyword()) :: integer()
      def estimate_index_size(entities, options \\ []) do
        Index.eslength(entities, options)
      end

      @doc false
      @deprecated "Use Publish.aggregate/2 instead"
      @spec index(entities :: Enumerable.t(), options :: keyword()) :: binary()
      def index(entities, options \\ []) do
        Index.aggregate(entities, options)
      end

      @doc false
      @deprecated "Use Publish.aggregate_stream/2 instead"
      @spec xml_stream(entities :: Entity.t() | Enumerable.t(), options :: keyword()) :: Enumerable.t()
      def xml_stream(entities, options \\ []) do
        SamlXml.aggregate_stream(entities, options)
      end

      @doc false
      @deprecated "Use Publish.eslength/2 instead"
      @spec estimate_xml_size(entities :: Enumerable.t(), options :: keyword()) :: integer()
      def estimate_xml_size(entities, options \\ []) do
        SamlXml.eslength(entities, options)
      end

      @doc false
      @deprecated "Use Publish.aggregate/2 instead"
      @spec xml(entities :: Enumerable.t(), options :: keyword()) :: binary()
      def xml(entities, options \\ []) do
        SamlXml.aggregate(entities, options)
      end

    end

  end

end