defmodule Smee.XMLProcessor.XMLProcessorBackend do

  defmacro __using__(opts) do


    id = Keyword.get(opts, :id, nil)
    if is_nil(id), do: raise "XMLProcessorBackend requires an :id!"
    tools = Keyword.get(opts, :tools, [])
    
    quote do

      @behaviour Smee.Behaviours.XMLProcessorBackend
      
      def id() do
        unquote(id)
      end

      def tools() do
        unquote(tools)
      end



    end
  end


end