defmodule Smee.Sigils do
  @moduledoc """
  `Smee.Sigils` provides a version of SweetXml's `~x` sigil for creating XPaths, optimised for working with SAML
    metadata. All of Smee's known XML namespaces will be automatically loaded for you.

  For more information please read [the official SweetXml documentation](https://hexdocs.pm/sweet_xml/SweetXml.html#module-the-x-sigil).

   `import Smee.Sigils` to use. If you are also importing SweetXml functions you should avoid loading both Smee and
    SweetXml's versions of this sigil:

  ```
    import SweetXml, except: [sigil_x: 2]
    import Smee.Sigils
  ```

  This sigil does not automatically precompile or cache, so it's advisable to use a module attribute to store the compiled
    xpath if you can.
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
