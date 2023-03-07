defmodule Smee.Security do

  @moduledoc """
  X
  """

  alias Smee.Metadata


  @doc """

  """
  @spec verify!(metadata :: Metadata.t()) :: Metadata.t()
  def verify!(metadata) do
    apply(selected_backend(), :verify!, [metadata])
  end

  @doc """

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
