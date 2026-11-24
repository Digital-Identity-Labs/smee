defmodule Smee.XMLProcessor.LibXMLTools do

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
      {:ok, nil} -> {:ok, nil}
      {:ok, ""} -> {:ok, nil}
      {:ok, xml} -> {:ok, xml}
      {:error, msg} -> {:error, "Cannot find #{entity_id} in metadata, error occurred! #{msg}"}
    end
  end

end