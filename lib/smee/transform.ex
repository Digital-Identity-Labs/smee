defmodule Smee.Transform do

  @moduledoc """
  X
  """

  alias Smee.XSLT
  alias Smee.Metadata

  @valid_until_s File.read! "priv/xslt/valid_until.xsl"
  @strip_comments_s File.read! "priv/xslt/strip_comments.xsl"
  @strip_idp_s File.read! "priv/xslt/strip_adfs_idp.xsl"
  @strip_sp_s File.read! "priv/xslt/strip_adfs_sp.xsl"

  @spec transform(metadata :: Metadata.t(), stylesheet :: binary, params :: keyword()) :: {:ok, Metadata.t()} | {:error, binary()}
  def transform(metadata, stylesheet, params \\ []) do
    case XSLT.transform(metadata.data, stylesheet, params) do
      {:ok, xml} -> {:ok, Metadata.update(metadata, xml)}
      {:error, msg} -> {:error, msg}
    end
  end

  @spec strip_comments(metadata :: Metadata.t()) :: {:ok, Metadata.t()} | {:error, binary()}
  def strip_comments(metadata) do
    transform(metadata, @strip_comments_s, [])
  end

  @spec valid_until(metadata :: Metadata.t(), date :: DateTime.t()) :: {:ok,  Metadata.t()} | {:error, binary()}
  def valid_until(metadata, date) do
    transform(metadata, @valid_until_s, [validUntil: date])
  end

  @spec valid_until!(metadata :: Metadata.t(), date :: DateTime.t()) :: Metadata.t()
  def valid_until!(metadata, date), do: unwrap_results(valid_until(metadata, date))

  @spec decruft_idp(metadata :: Metadata.t()) :: {:ok, Metadata.t()} | {:error, binary()}
  def strip_adfs(metadata) do
    transform(metadata, @strip_idp_s, [])
  end

  @spec decruft_sp(metadata :: Metadata.t()) :: {:ok, Metadata.t()} | {:error, binary()}
  def strip_adfs(metadata) do
    transform(metadata, @strip_sp_s, [])
  end

  ################################################################################

  @spec unwrap_results(results :: tuple()) :: Metadata.t()
  defp unwrap_results(results) do
    case results do
      {:ok, data} -> data
      {:error, msg} -> raise msg
    end
  end

end
