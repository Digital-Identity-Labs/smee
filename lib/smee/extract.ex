defmodule Smee.Extract do

  @moduledoc """
  X
  """

  alias Smee.XSLT
  alias Smee.Metadata
  alias Smee.Entity

  @list_ids_s File.read! "priv/xslt/list_ids.xsl"
  @list_entity_attrs_s File.read! "priv/xslt/list_entity_attrs.xsl"
  @list_mdui_s File.read! "priv/xslt/list_mdui.xsl"
  @entity_s File.read! "priv/xslt/extract_entity.xsl"

  @spec list_ids(metadata :: Metadata.t()) :: list(binary())
  def list_ids(metadata)  do
    case XSLT.transform(metadata.data, @list_ids_s, []) do
      {:ok, txt} -> String.split(txt)
      {:error, msg} -> []
    end
  end

  @spec list_entity_attrs(metadata ::Metadata.t()) :: map()
  def list_entity_attrs(%Metadata{} = metadata)  do
    case XSLT.transform(metadata.data, @list_entity_attrs_s, []) do
      {:ok, txt} -> build_ea_tree(txt)
      {:error, msg} -> %{}
    end
  end

  def list_entity_attrs(metadata)  do
   raise "Only works with Metadata structs!"
  end

  @spec entity!(metadata :: Metadata.t(), uri :: binary()) :: Entity.t()
  def entity!(metadata, uri) do
    case XSLT.transform(metadata.data, @entity_s, [entityID: uri]) do
      {:ok, ""} -> raise "Cannot find #{uri} in metadata!"
      {:ok, xml} -> Entity.derive(xml, metadata)
      {:error, msg} -> raise "Cannot find #{uri} in metadata, error occurred! #{msg}"
      end
  end

  @spec mdui_info(metadata ::Metadata.t()) :: map()
  def mdui_info(%Metadata{} = metadata)  do
    case XSLT.transform(metadata.data, File.read!("priv/xslt/list_mdui.xsl"), []) do
      {:ok, txt} -> build_mdui_records(txt)
      {:error, msg} -> %{}
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

  defp build_mdui_records(txt) do
    txt
    |> String.splitter("\n")
    |> Stream.map(fn line -> String.split(line, "§") end)
    |> Stream.map(fn parts -> List.zip([[:entity_id, :idp_displayname, :idp_description, :idp_information_url, :idp_privacy_url, :sp_displayname, :sp_description, :sp_information_url, :sp_privacy_url, :org_name, :org_displayname], parts]) end)
    |> Stream.map(fn tuples -> Map.new(tuples) end)
    |> Enum.to_list()
  end

end
