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

      @spec stream(entities :: Enumerable.t(), options :: keyword()) :: Enumerable.t()
      def stream(entities, options \\ []) do
        if options[:aggregate] == false do
          entities
          |> extracts(options)
          |> encoder(options)
        else
          Stream.concat(
            [
              header(options),
              body(entities, options),
              footer(options)
            ]
          )
        end
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
        |> stream(options)
        |> Stream.map(fn x -> byte_size(x) end)
        |> Enum.reduce(0, fn x, acc -> x + acc end)
      end

      @spec text(entities :: Enumerable.t(), options :: keyword()) :: binary()
      def text(entities, options \\ []) do
        entities
        |> stream(options)
        |> Enum.to_list()
        |> Enum.join("")
      end

      @spec data(entities :: Enumerable.t(), options :: keyword()) :: binary()
      def data(entities, options \\ []) do
        text(entities, options)
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
        stream: 2,
        encoder: 2,
        header: 1,
        footer: 1,
        body: 2,
        separator: 1,
        eslength: 2,
        text: 2,
        data: 2,
        write: 2
      ]

    end
  end



end
