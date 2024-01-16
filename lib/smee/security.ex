defmodule Smee.Security do
  @moduledoc """
  `Smee.Security` uses XML signatures to provide anti-tampering and origin authentication features.

  Most metadata from national research and education networks is signed to add an extra layer of security for users:
    altered metadata can create security and privacy vulnerabilities for organsations.

  At the moment only signature verification on Metadata structs is supported.
  """

  alias Smee.Metadata

  @doc """
  Returns a metadata struct with `verified: true` set if verification passes, or raises an exception.
  """
  @spec verify!(metadata :: Metadata.t()) :: Metadata.t()
  def verify!(metadata) do
    apply(selected_backend(), :verify!, [metadata])
  end

  @doc """
  Returns a metadata struct in an :ok/:error tuple, with `verified: true` set if verification passes.
  """
  @spec verify(metadata :: Metadata.t()) :: {:ok, Metadata.t()} | {:error, binary()}
  def verify(metadata) do
    try do
      {:ok, verify!(metadata)}
    rescue
      e -> {:error, e.message}
    end
  end

  @doc """
  Returns true or false depending on verification status of the passed metadata.

  Already-verified metadata will not be reverified.
  """
  @spec verify?(metadata :: Metadata.t()) :: boolean()
  def verify?(%Metadata{verified: true}), do: true

  def verify?(metadata) do
    try do
      %Metadata{verified: value} = verify!(metadata)
      value
    rescue
      _ -> false
    end
  end

  #  def expired?(metadata) do
  #
  #  end

  ################################################################################

  @spec selected_backend() :: atom()
  defp selected_backend() do
    Smee.SysCfg.security_backend()
  end
end
