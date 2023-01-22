defmodule Smee.Transform do

  alias Smee.XSLT
  alias Smee.Metadata

  @valid_until_s File.read! "priv/xslt/valid_until.xsl"
  @strip_comments_s File.read! "priv/xslt/strip_comments.xsl"

  def transform(md, stylesheet, params \\ []) do
    case XSLT.transform(md.data, stylesheet, params) do
      {:ok, xml} -> {:ok, Metadata.update(md, xml)}
      {:error, msg} -> {:error, msg}
    end
  end

  def strip_comments(md) do
    transform(md, @strip_comments_s, [])
  end

  def valid_until(md, date) do
    transform(md, @valid_until_s, [validUntil: date])
  end

  def valid_until!(md, date), do: wrap_results(valid_until(md, date))

  defp wrap_results(results) do
    case results do
      {:ok, data} -> data
      {:error, msg} -> raise msg
    end
  end

end
