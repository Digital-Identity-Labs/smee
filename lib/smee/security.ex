defmodule Smee.Security do
  
  require Logger
  
  @moduledoc """
  `Smee.Security` uses XML signatures to provide anti-tampering and origin authentication features.

  Most metadata from national research and education networks is signed to add an extra layer of security for users:
    altered metadata can create security and privacy vulnerabilities for organisations.

  At the moment only signature verification on Metadata structs is supported.
  """

  alias Smee.Metadata
  alias Smee.XMLProcessor
  alias Smee.SigningCertificate

  @doc """
  Returns a metadata struct with `verified: true` set if verification passes, or raises an exception.
  """
  @spec verify!(metadata :: Metadata.t()) :: Metadata.t()
  def verify!(metadata) do
    cert_file = SigningCertificate.prepare_file!(metadata)
    XMLProcessor.verify!(metadata, cert_file, [])
  end

  @doc """
  Returns a metadata struct in an :ok/:error tuple, with `verified: true` set if verification passes.
  """
  @spec verify(metadata :: Metadata.t()) :: {:ok, Metadata.t()} | {:error, binary()}
  def verify(metadata) do
    with {:ok, cert_file} <- SigningCertificate.prepare_file(metadata) do
      XMLProcessor.verify(metadata, cert_file, [])
    end
  end

  @doc """
  Returns true or false depending on verification status of the passed metadata.

  Already-verified metadata will not be reverified.
  """
  @spec verify?(metadata :: Metadata.t()) :: boolean()
  def verify?(%Metadata{verified: true}), do: true

  def verify?(metadata) do
    with {:ok, cert_file} <- SigningCertificate.prepare_file(metadata) do
      XMLProcessor.verify?(metadata, cert_file, [])
    else
      _ -> Logger.error("Cannot verify metadata because certificate preparation has failed") 
        false
    end
  end

end
