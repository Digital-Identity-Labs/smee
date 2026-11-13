defmodule Smee.XMLProcessor.XMLProcessorBackend do

  defmacro __using__(opts) do


    id = Keyword.get(opts, :id, nil)
    if is_nil(id), do: raise "XMLProcessorBackend requires an :id!"
    tools = Keyword.get(opts, :tools, [])

    quote do

      @behaviour Smee.Behaviours.XMLProcessorBackend

      defmacro unimplemented(opts) do
        quote do
          opts = unquote(opts)
          raise "Unimplemented or unsupported XML Processing Backend feature!"
        end
      end
      
      def id() do
        unquote(id)
      end

      def tools() do
        unquote(tools)
      end

      def tidy(xml, opts \\ []) do
        unimplemented(opts)
      end

      def well_formed(xml, opts \\ []) do
        unimplemented(opts)
      end

      def validate(xml, opts \\ []) do
        unimplemented(opts)
      end

      def verify(xml, certificates, opts \\ []) do
        unimplemented(opts)
      end

      def sign(xml, certificate, opts \\ []) do
        unimplemented(opts)
      end

      def transform(xml, stylesheet, params \\ [], opts \\ []) do
        unimplemented(opts)
      end

      def list_ids(xml, opts \\ []) do
        unimplemented(opts)
      end

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

     
      
#      defp unimplemented(opts) do
#        raise "Unimplemented or unsupported XML Processing Backend feature!\nYou are currently using #{
#          Smee.XMLProcessor.backend(opts[:backend])
#        } (:#{
#          Smee.XMLProcessor.backend(opts[:backend]).id
#        })"
#      end

    end

  end


end