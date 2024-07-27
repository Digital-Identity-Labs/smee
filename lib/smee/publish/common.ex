defmodule Smee.Publish.Common do

  defmacro __using__(opts) do
    quote do

      @moduledoc false

      alias Smee.Entity
      alias Smee.XmlMunger

      @spec format() :: atom()
      def format() do
        :none
      end

      @spec extract(entity :: Entity.t(), options :: keyword()) :: struct()
      def extract(entity, options \\ []) do
        %{}
      end

      @spec stream(entities :: Enumerable.t(), options :: keyword()) :: Enumerable.t()
      def stream(entities, _options \\ []) do
        Stream.concat([], [])
      end

      @spec eslength(entities :: Enumerable.t(), options :: keyword()) :: integer()
      def eslength(entities, options \\ []) do
        0
      end

      @spec text(entities :: Enumerable.t(), options :: keyword()) :: binary()
      def text(entities, options \\ []) do
        ""
      end

      @spec data(entities :: Enumerable.t(), options :: keyword()) :: binary()
      def data(entities, options \\ []) do
        text(entities, options)
      end

      @spec write(entities :: Enumerable.t(), options :: keyword()) :: list(binary())
      def write(entities, options \\ []) do
        []
      end

      defoverridable [format: 0, extract: 2, stream: 2, eslength: 2, text: 2, data: 2, write: 2]

    end
  end



end
