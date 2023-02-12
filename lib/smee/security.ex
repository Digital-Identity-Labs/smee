defmodule Smee.Security do

  alias Smee.Metadata

  def verify!(metadata) do
    apply(selected_backend(), :verify!, [metadata])
  end

  def verify(metadata) do
    try do
      {:ok, verify!(metadata)}
    rescue
      e -> {:error, e.message}
    end
  end

  def verify?(%Metadata{verified: true}), do: true

  def verify?(metadata) do
    try do
      %Metadata{verified: value} = verify!(metadata)
      value
    rescue
      e -> false
    end
  end

  #  def expired?(metadata) do
  #
  #  end

  ################################################################################


  defp selected_backend() do
    Smee.SysCfg.security_backend()
  end

end
