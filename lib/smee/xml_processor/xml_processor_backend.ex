defmodule Smee.XMLProcessor.XMLProcessorBackend do

  @moduledoc false
  
  defmacro __using__(opts) do
    
    id = Keyword.get(opts, :id, nil)
    if is_nil(id), do: raise "XMLProcessorBackend requires an :id!"
    tools = Keyword.get(opts, :tools, [])
    status = Keyword.get(opts, :status, :supported)

    quote do

      @behaviour Smee.Behaviours.XMLProcessorBackend

      @doc false
      defmacro unimplemented(opts) do
        quote do
          opts = unquote(opts)
          {:error, "Unimplemented or unsupported XML Processing Backend feature!"}
        end
      end

      @impl true
      @doc false
      def id() do
        unquote(id)
      end

      @impl true
      @doc false
      def tools() do
        unquote(tools)
      end

      @impl true
      @doc false
      def status() do
        unquote(status)
      end
      
      @impl true
      @doc false
      def tidy(xml, opts \\ []) do
        unimplemented(opts)
      end

      @impl true
      @doc false
      def well_formed(xml, opts \\ []) do
        unimplemented(opts)
      end

      @impl true
      @doc false
      def validate(xml, opts \\ []) do
        unimplemented(opts)
      end

      @impl true
      @doc false
      def verify(xml, certificates, opts \\ []) do
        unimplemented(opts)
      end

      @impl true
      @doc false
      def sign(xml, certificate, opts \\ []) do
        unimplemented(opts)
      end

      @impl true
      @doc false
      def transform(xml, stylesheet, params \\ [], opts \\ []) do
        unimplemented(opts)
      end

      @impl true
      @doc false
      def list_ids(xml, opts \\ []) do
        unimplemented(opts)
      end

      @impl true
      @doc false
      def extract_entity(xml, entity_id, opts \\ []) do
        unimplemented(opts)
      end

      defoverridable [
        tidy: 2,
        well_formed: 2,
        validate: 2,
        verify: 3,
        sign: 3,
        transform: 4,
        list_ids: 2,
        extract_entity: 3,
      
      ]
      
      ##################

    end

  end


end