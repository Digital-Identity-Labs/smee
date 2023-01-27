defmodule Smee.Extract do

  alias Smee.XSLT
  alias Smee.Metadata

  @list_ids_s File.read! "priv/xslt/list_ids.xsl"
  @list_entity_attrs_s File.read! "priv/xslt/list_entity_attrs.xsl"

#  def transform(md, stylesheet, params \\ []) do
#    case XSLT.transform(md.data, stylesheet, params) do
#      {:ok, xml} -> {:ok, Metadata.update(md, xml)}
#      {:error, msg} -> {:error, msg}
#    end
#  end

  def list_ids(md)  do
    case XSLT.transform(md.data, @list_ids_s, []) do
      {:ok, txt} -> String.split(txt)
      {:error, msg} -> []
    end
  end

  def list_entity_attrs(%Metadata{} = md)  do
    case XSLT.transform(md.data, @list_entity_attrs_s, []) do
      {:ok, txt} -> build_ea_tree(txt)
      {:error, msg} -> %{}
    end
  end

  def list_entity_attrs(md)  do
   raise "Only works with Metadata structs!"
  end

  defp wrap_results(results) do
    case results do
      {:ok, data} -> data
      {:error, msg} -> raise msg
    end
  end

  defp build_ea_tree(txt) do
    txt
    |> String.splitter("|")
    |> Stream.uniq()
    |> Stream.map(fn line -> String.split(line) end)
    |> Stream.reject(fn list -> list == [] end)
    |> Stream.map(fn [k,v] ->{k,v} end)
    |> Enum.to_list
    |> Enum.group_by(&elem(&1, 0), &elem(&1, 1))
  end

end
