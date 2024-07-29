defmodule Smee.Publish.Common do

  defmacro __using__(opts) do
    quote do

      @moduledoc false

      alias Smee.Entity
      alias Smee.Utils

      @spec format() :: atom()
      def format() do
        :null
      end

      @spec ext() :: atom()
      def ext() do
        "txt"
      end

      @spec id_type() :: atom()
      def id_type() do
        :hash
      end

      @spec filter(entities :: Enumerable.t(), options :: keyword()) :: Enumerable.t()
      def filter(entities, options \\ []) do
        entities
      end

      @spec extract(entity :: Entity.t(), options :: keyword()) :: struct()
      def extract(entity, options \\ []) do
        %{}
      end

      @spec aggregate_stream(entities :: Enumerable.t(), options :: keyword()) :: Enumerable.t()
      def aggregate_stream(entities, options \\ []) do
        options = Keyword.merge(options, [in_aggregate: true])
        Stream.concat(
          [
            headers(options),
            body_stream(entities, options),
            footers(options)
          ]
        )
      end

      @spec items_stream(entities :: Enumerable.t(), options :: keyword()) :: Enumerable.t()
      def items_stream(entities, options \\ []) do
        entities
        |> filter(options)
        |> Stream.with_index()
        |> Stream.map(fn {e, i} -> {item_id(e, i, options), extract(e, options)} end)
        |> Stream.map(fn {id, e} -> {id, encode(e, options)} end)
      end

      def encode(entities, options \\ []) do
        ""
      end

      def headers(options) do
        []
      end

      def body_stream(entities, options) do
        entities
        |> filter(options)
        |> Stream.map(fn e -> extract(e, options) end)
        |> Stream.map(fn e -> encode(e, options) end)
        |> Stream.intersperse(separator(options))
        #|> Stream.drop(-1)
      end

      def footers(options) do
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
        |> Map.new()
      end

      @spec write_aggregate(entities :: Enumerable.t(), options :: keyword()) :: list(binary())
      def write_aggregate(entities, options \\ []) do
        options = Keyword.merge([to: File.cwd!()], options)
        :ok = check_dir!(options)
        filename = aggregate_filename(options)
        file = File.stream!(filename)

        entities
        |> aggregate_stream(options)
        |> Enum.into(file)
        Path.absname(filename)
      end

      @spec write_items(entities :: Enumerable.t(), options :: keyword()) :: list(binary())
      def write_items(entities, options \\ []) do
        options = Keyword.merge([to: File.cwd!()], options)
        :ok = check_dir!(options)

        entities
        |> items_stream(options)
        |> Stream.map(
             fn {id, item} ->
               filename = item_filename(id, options)
               File.write!(filename, item)
               if options[:alias] && options[:id] in [:entity_id, :uri] do
                 alias = item_aliasname(id, options)
                 if File.exists?(alias), do: File.rm!(alias)
                 File.ln_s!(Path.basename(filename), alias)
               end
               Path.absname(filename)
             end
           )
        |> Enum.to_list()
      end

      def item_id(entity, i, options) do
        case (options[:id] || id_type()) do
          :hash -> entity.uri_hash
          :entity_id -> entity.uri
          :uri -> entity.uri
          :number -> i
          :mdq -> "{sha1}#{entity.uri_hash}"
          _ -> entity.uri_hash
        end
      end

      def item_filename(id, options) do
        Path.join("#{options[:to]}", "#{sanitize_filename(id, options)}.#{ext()}")
      end

      def item_aliasname(id, options) do
        Path.join("#{options[:to]}", "#{Utils.sha1(id)}.#{ext()}")
      end

      def aggregate_filename(options) do
        (options[:filename] || Path.join("#{options[:to]}", "#{format()}_aggregate.#{ext()}"))
      end

      def check_dir!(options) do
        dir = options[:to]
        if File.exists?(dir) && !File.dir?(dir) do
          raise "specify to: directory exists but is not a directory!"
        else
          File.mkdir_p!(dir)
          :ok
        end
      end

      def sanitize_filename(filename, options) do
        if options[:id] in [:hash, :number, :mdq, nil] do
          filename
        else
          filename = filename
                     |> String.replace_leading("https://", "")
                     |> String.replace_leading("http://", "")
                     |> String.replace([".", "/"], "_")
                     |> String.replace_trailing("_", "")
                     |> Zarex.sanitize()
        end
      end

      def compact_map(map) do
        map
        |> Enum.reject(fn {k, v} -> (v == false) or is_nil(v) or (is_list(v) and length(v) == 0)  end)
        |> Map.new()
      end

      defoverridable [
        format: 0,
        filter: 2,
        extract: 2,
        items_stream: 2,
        aggregate_stream: 2,
        encode: 2,
        headers: 1,
        footers: 1,
        body_stream: 2,
        separator: 1,
        eslength: 2,
        items: 2,
        aggregate: 2,
        write_aggregate: 2,
        write_items: 2,
        ext: 0
      ]

    end
  end

end
