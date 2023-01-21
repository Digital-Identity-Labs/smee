defmodule Smee.Transform do

  alias Smee.XSLT
  alias Smee.Metadata

  @valid_until_t File.read! "priv/xslt_templates/valid_until.xs"

  def transform(md, template, params \\ []) do
    case XSLT.transform(md.data, template, params) do
      {:ok, xml} -> {:ok, Metadata.update(md, xml)}
      {:error, msg} -> {:error, msg}
    end
  end
  
  def valid_until(md, date) do
    transform(md, @valid_until_t, [validUntil: date])
  end

  def valid_until!(md, date), do: wrap_results(valid_until(md, date))

  defp wrap_results(results) do
    case results do
      {:ok, data} -> data
      {:error, msg} -> raise msg
    end
  end

end
