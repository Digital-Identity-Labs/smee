defmodule Smee.Sigils do
  @moduledoc """
  `Smee.Sigils` provides

  """

  alias Smee.XmlCfg

  @doc """
  A convenient replacement for

  """

  # no spec needed
  def sigil_x(str, opts) do
    xpath = SweetXml.sigil_x(str, opts)
    %SweetXpath{xpath | namespaces: XmlCfg.erlang_namespaces() ++ xpath.namespaces}
  end

  # Defoverridable makes the given functions in the current module overridable
  defoverridable [sigil_x: 2]
end
