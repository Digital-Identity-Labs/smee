defmodule Smee.Filter do

  alias Smee.XSLT
  alias Smee.Metadata

  def run!(stream) do
    
  end

  def xpath(enum, bool) do

  end

  def idps(enum, bool) do
    
  end

  def sps(enum, bool) do

  end

  def aas(enum, bool) do

  end

  defp wrap_results(results) do
    case results do
      {:ok, data} -> data
      {:error, msg} -> raise msg
    end
  end

end
