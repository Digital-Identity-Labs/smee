defmodule Smee.XMLProcessor.Legacy do

  @moduledoc """
  A backend for XML processing that relies on external UNIX tools (deprecatred)
  
  This code is almost the same as that used by earlier versions of Smee, and is provided in case of any issues with the
    two new backend options. However, it has issues of its own and is deprecated. Please use one of the others if you can.
  
  ### The Legacy Backend: Rambo and Rust (TLDR: avoid it)

  The Legacy backend uses an Elixir library called [Rambo](https://hex.pm/packages/rambo) to run external utilities like xsltproc. Rambo 
  relies on a small compiled shim that is provided pre-compiled for various architectures or automatically built during installation.

  - If your system does not match any of the supplied binary shims, you will need to have a rust compiler installed so Rambo
  can build the shim itself. 
  - Version 0.3.4 of Rambo has an additional problem: it does not ship with a precompiled binary for M1 Macs, *and it also does
  not automatically build one*. Smee works around that with an explicit compile step in `mix.exs`, but it prevents Smee from
  being used in Elixir .exs scripts on M1 Macs unless you copy the compiled shim from Smee into your script's build directory.
  Hopefully this will be fixed in later versions of Rambo. 
  - If you are using a modern M1/M2/M3 Mac you may need to explicitly include Rambo as a dependency in your project.

  This is why the Legacy backend (the original XML processing code in Smee) is now deprecated. The default backend does not
  require this fix, and the optional LibXMLTools backend does not depend on Rambo.

  If you are using Smee in your project and wish to use the legacy backend on a modern Mac you must explicitly declare its
   compiler in your mix.exs file:
 
   ```elixir
  # ...
  compilers: Mix.compilers() ++ [:rambo],
  # ...
  ```
  
  ### Specifying as the default XML processing backend
  
  ```elixir
  config :smee, :xml_processor, :legacy
  ```
  """
  
  use Smee.XMLProcessor.XMLProcessorBackend, id: :legacy, tools: ["xmllint", "xsltproc", "xmlsec1"], status: :deprecated
  
  require Logger

  alias Smee.XMLProcessor.Legacy.Xmllint
  alias Smee.XMLProcessor.Legacy.Xmlsec1
  alias Smee.XMLProcessor.Legacy.Xsltproc

  @list_ids_s File.read!(Application.app_dir(:smee, "priv/xslt/list_ids.xsl"))
  @entity_s File.read!(Application.app_dir(:smee, "priv/xslt/extract_entity.xsl"))

  @impl true
  def tidy(xml, opts) do
    Xmllint.tidy(xml, opts)
  end

  @impl true
  def well_formed(xml, opts) do
    Xmllint.well_formed(xml, opts)
  end

  @impl true
  def validate(xml, opts) do
    Xmllint.validate(xml, opts)
  end

  @impl true
  def verify(xml, certificates, opts) do
    Xmlsec1.verify(xml, certificates, opts)
  end

  @impl true
  def transform(xml, stylesheet, params, opts) do
    Xsltproc.transform(xml, stylesheet, params, opts)
  end

  @impl true
  def list_ids(xml, _opts) do
    case transform(xml, @list_ids_s, []) do
      {:ok, txt} -> {:ok, String.split(txt)}
      {:error, msg} -> {:error, msg}
    end
  end

  @impl true
  def extract_entity(xml, entity_id, _opts) do
    case transform(xml, @entity_s, entityID: entity_id) do
      {:ok, ""} -> {:ok, nil}
      {:ok, xml} -> {:ok, xml}
      {:error, msg} -> {:error, "Cannot find #{entity_id} in metadata, error occurred! #{msg}"}
    end
  end

end