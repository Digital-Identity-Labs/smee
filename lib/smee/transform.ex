defmodule Smee.Transform do

  @moduledoc """
  Tools for manipulating metadata XML.

  This module is intended to make common and relatively simple actions on potentially large XML files more efficiently than
  processing a metadata or entities using xmerl, and may rely on external tools such as `xsltproc`.

  These functions are useful for pre-processing metadata XML before it's broken up into entity struct,
  and to speed-up the internal workings of other modules.

  """

  alias Smee.XSLT
  alias Smee.Metadata

  @valid_until_s File.read! "priv/xslt/valid_until.xsl"
  @strip_comments_s File.read! "priv/xslt/strip_comments.xsl"
  @strip_idp_s File.read! "priv/xslt/strip_adfs_idp.xsl"
  @strip_sp_s File.read! "priv/xslt/strip_adfs_sp.xsl"


  @doc """
  Applies an XSLT stylesheet to a metadata struct, returning a transformed metadata struct in an :ok/error tuple
  """
  @spec transform(metadata :: Metadata.t(), stylesheet :: binary, params :: keyword()) :: {:ok, Metadata.t()} | {:error, binary()}
  def transform(metadata, stylesheet, params \\ []) do
    case XSLT.transform(metadata.data, stylesheet, params) do
      {:ok, xml} -> {:ok, Metadata.update(metadata, xml)}
      {:error, msg} -> {:error, msg}
    end
  end


  @doc """
  Returns a metadata struct with all comments removed, in an :ok/:error struct
  """
  @spec strip_comments(metadata :: Metadata.t()) :: {:ok, Metadata.t()} | {:error, binary()}
  def strip_comments(metadata) do
    transform(metadata, @strip_comments_s, [])
  end


  @doc """
  Returns a metadata struct with the validUntil date updated, in an :ok/:error struct
  """
  @spec valid_until(metadata :: Metadata.t(), date :: DateTime.t()) :: {:ok,  Metadata.t()} | {:error, binary()}
  def valid_until(metadata, date) do
    transform(metadata, @valid_until_s, [validUntil: DateTime.to_iso8601(date)])
  end

  @doc """
  Returns a metadata struct with the validUntil date updated, or raises if an error occurs
  """
  @spec valid_until!(metadata :: Metadata.t(), date :: DateTime.t()) :: Metadata.t()
  def valid_until!(metadata, date), do: unwrap_results(valid_until(metadata, date))

  @doc """
  Strips various extraneous parts from the metadata and returns a new struct in an :ok/:error tuple
  """
  @spec decruft_idp(metadata :: Metadata.t()) :: {:ok, Metadata.t()} | {:error, binary()}
  def decruft_idp(metadata) do
    transform(metadata, @strip_idp_s, [])
  end

  @doc """
  Strips various extraneous parts from the metadata and returns a new struct in an :ok/:error tuple
  """
  @spec decruft_sp(metadata :: Metadata.t()) :: {:ok, Metadata.t()} | {:error, binary()}
  def decruft_sp(metadata) do
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
