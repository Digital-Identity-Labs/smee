defmodule Smee.Extract do

  alias Smee.XSLT
  alias Smee.Metadata

  @list_ids_s File.read! "priv/xslt/list_ids.xsl"

#  def transform(md, stylesheet, params \\ []) do
#    case XSLT.transform(md.data, stylesheet, params) do
#      {:ok, xml} -> {:ok, Metadata.update(md, xml)}
#      {:error, msg} -> {:error, msg}
#    end
#  end

  def list_ids(md)  do
    case XSLT.transform(md.data, @list_ids_s, []) do
      {:ok, xml} -> String.split(xml)
      {:error, msg} -> []
    end
  end

  defp wrap_results(results) do
    case results do
      {:ok, data} -> data
      {:error, msg} -> raise msg
    end
  end

end
