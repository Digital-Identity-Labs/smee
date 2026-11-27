defmodule Smee.XMLProcessor.LibXMLTools do

  @moduledoc """
  A backend for XML processing that relies on external UNIX tools
  
  This is an alternative to `Smee.XMLProcessor.Uppsala` that executes commandline tools to process XML. It uses the
   excellent new [Forcola](https://hex.pm/packages/forcola) package to safely manage external processes. 
  
  This backend is useful if you cannot compile the Uppsala NIF (or fetch it), or want quicker recovery of memory at the
    cost of extra processing time.
  
  ### Specifying as the default XML processing backend
  
  ```elixir
  config :smee, :xml_processor, :libxml_tools
  ```

  """
  
  use Smee.XMLProcessor.XMLProcessorBackend, id: :libxml_tools, tools: ["xmllint", "xsltproc", "xmlsec1"]

  require Logger

  alias Smee.XMLProcessor.LibXMLTools.Xmllint
  alias Smee.XMLProcessor.LibXMLTools.Xmlsec1
  alias Smee.XMLProcessor.LibXMLTools.Xsltproc

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