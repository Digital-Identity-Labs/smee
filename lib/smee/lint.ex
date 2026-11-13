defmodule Smee.Lint do
  @moduledoc """
  Lint runs basic XML quality checks against XML strings
  """

  alias Smee.XMLProcessor

  @doc """
  Validates XML - checks that it is well-formed and complies with SAML metadata schema. It does **not* check
    signatures or expiry.
  """
  @spec validate(xml :: binary(), options :: keyword()) :: {:ok, binary()} | {:error, binary()}
  def validate(xml, options \\ []) do
    XMLProcessor.validate(xml, options)
  end

  @doc false
  @spec tidy(xml :: binary(), options :: keyword()) :: {:ok, binary()} | {:error, binary()}
  def tidy(xml, options \\ []) do
    XMLProcessor.tidy(xml, options)
  end

  @doc false
  @spec well_formed(xml :: binary(), options :: keyword()) :: {:ok, binary()} | {:error, binary()}
  def well_formed(xml, options \\ []) do
    XMLProcessor.well_formed(xml, options)
  end

end
