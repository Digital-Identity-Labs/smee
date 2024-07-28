defmodule Smee.Publish.Common do

  defmacro __using__(opts) do
    quote do

      @moduledoc false

      alias Smee.Entity

      @spec format() :: atom()
      def format() do
        :null
      end

      @spec filter(entities :: Enumerable.t(), options :: keyword()) :: Enumerable.t()
      def filter(entities, options \\ []) do
        entities
      end

      @spec extract(entity :: Entity.t(), options :: keyword()) :: struct()
      def extract(entity, options \\ []) do
        %{}
      end

      @spec extracts(entities :: Enumerable.t(), options :: keyword()) :: Enumerable.t()
      def extracts(entities, options \\ []) do
        entities
        |> filter(options)
        |> Stream.map(fn e -> extract(e, options) end)
      end

      @spec aggregate_stream(entities :: Enumerable.t(), options :: keyword()) :: Enumerable.t()
      def aggregate_stream(entities, options \\ []) do
        Stream.concat(
          [
            header(options),
            body(entities, options),
            footer(options)
          ]
        )
      end

      @spec items_stream(entities :: Enumerable.t(), options :: keyword()) :: Enumerable.t()
      def items_stream(entities, options \\ []) do
        entities
        |> extracts(options)
        |> encoder(options)
      end

      def encoder(entities, options \\ []) do
        entities
        |> Stream.map(fn e -> "" end)
      end

      def header(options) do
        []
      end

      def body(entities, options) do
        entities
        |> extracts(options)
        |> encoder(options)
        |> Stream.intersperse(separator(options))
        #|> Stream.drop(-1)
      end

      def footer(options) do
        []
      end

      def separator(options) do
        ""
      end

      @spec eslength(entities :: Enumerable.t(), options :: keyword()) :: integer()
      def eslength(entities, options \\ []) do
        entities
        |> aggregate_stream(options)
        |> Stream.map(fn x -> byte_size(x) end)
        |> Enum.reduce(0, fn x, acc -> x + acc end)
      end

      @spec aggregate(entities :: Enumerable.t(), options :: keyword()) :: binary()
      def aggregate(entities, options \\ []) do
        entities
        |> aggregate_stream(options)
        |> Enum.to_list()
        |> Enum.join("")
      end

      @spec items(entities :: Enumerable.t(), options :: keyword()) :: list(binary())
      def items(entities, options \\ []) do
        entities
        |> items_stream(options)
        |> Enum.to_list()
        |> Enum.join("")
      end

      @spec write(entities :: Enumerable.t(), options :: keyword()) :: list(binary())
      def write(entities, options \\ []) do
        []
      end

      defoverridable [
        format: 0,
        filter: 2,
        extracts: 2,
        extract: 2,
        items_stream: 2,
        aggregate_stream: 2,
        encoder: 2,
        header: 1,
        footer: 1,
        body: 2,
        separator: 1,
        eslength: 2,
        items: 2,
        aggregate: 2,
        write: 2
      ]

    end
  end

end
