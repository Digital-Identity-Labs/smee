defmodule Smee.Publish.Index do

  @moduledoc false

  alias Smee.Entity
  alias Smee.XmlMunger

  @doc """
  Returns a streamed index file, a plain text list of entity IDs.
  """
  @spec stream(entities :: Enumerable.t(), options :: keyword()) :: Enumerable.t()
  def stream(entities, _options \\ []) do
    entities
    |> Stream.map(fn e -> "#{e.uri}\n" end)
  end

  @doc """
  Returns the estimated size of a streamed index file without generating it in advance.
  """
  @spec estimate_size(entities :: Enumerable.t(), options :: keyword()) :: integer()
  def estimate_size(entities, options \\ []) do
    stream(entities, options)
    |> Stream.map(fn x -> byte_size(x) end)
    |> Enum.reduce(0, fn x, acc -> x + acc end)
  end

  @doc """
  Returns an index text document
  """
  @spec text(entities :: Enumerable.t(), options :: keyword()) :: binary()
  def text(entities, options \\ []) do
    stream(entities, options)
    |> Enum.to_list
    |> Enum.join("\n")
  end


end
