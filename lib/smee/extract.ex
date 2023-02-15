defmodule Smee.Extract do

  @moduledoc """
  X
  """

  alias Smee.XSLT
  alias Smee.Metadata
  alias Smee.Entity

  @list_ids_s File.read! "priv/xslt/list_ids.xsl"
  @list_entity_attrs_s File.read! "priv/xslt/list_entity_attrs.xsl"
  @entity_s File.read! "priv/xslt/extract_entity.xsl"

  @spec list_ids(metadata :: %Metadata{}) :: list(binary())
  def list_ids(metadata)  do
    case XSLT.transform(metadata.data, @list_ids_s, []) do
      {:ok, txt} -> String.split(txt)
      {:error, msg} -> []
    end
  end

  @spec list_entity_attrs(metadata :: %Metadata{}) :: map()
  def list_entity_attrs(%Metadata{} = metadata)  do
    case XSLT.transform(metadata.data, @list_entity_attrs_s, []) do
      {:ok, txt} -> build_ea_tree(txt)
      {:error, msg} -> %{}
    end
  end

  def list_entity_attrs(metadata)  do
   raise "Only works with Metadata structs!"
  end

  @spec entity!(metadata :: %Metadata{}, uri :: binary()) :: %Entity{}
  def entity!(metadata, uri) do
    case XSLT.transform(metadata.data, @entity_s, [entityID: uri]) do
      {:ok, xml} -> Entity.derive(xml, metadata)
      {:error, msg} -> raise "Cannot find #{uri} in metadata!"
      end
  end

  ################################################################################

  @spec wrap_results(results :: tuple()) :: any()
  defp wrap_results(results) do
    case results do
      {:ok, data} -> data
      {:error, msg} -> raise msg
    end
  end

  @spec build_ea_tree(txt :: binary()) :: map()
  defp build_ea_tree(txt) do
    txt
    |> String.splitter("|")
    |> Stream.uniq()
    |> Stream.map(fn line -> String.split(line) end)
    |> Stream.reject(fn list -> list == [] end)
    |> Stream.map(fn [k, v] -> {k, v} end)
    |> Enum.to_list
    |> Enum.group_by(&elem(&1, 0), &elem(&1, 1))
  end

end
