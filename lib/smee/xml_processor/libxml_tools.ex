defmodule Smee.XMLProcessor.LibXMLTools do

  use Smee.XMLProcessor.XMLProcessorBackend, id: :libxml_tools, tools: ["xmllint", "xsltproc", "xmlsec1"]

  require Logger

  alias Smee.XMLProcessor.LibXMLTools.Xmllint
  alias Smee.XMLProcessor.LibXMLTools.Xmlsec1
  alias Smee.XMLProcessor.LibXMLTools.Xsltproc

  @list_ids_s File.read!(Application.app_dir(:smee, "priv/xslt/list_ids.xsl"))
  @entity_s File.read!(Application.app_dir(:smee, "priv/xslt/extract_entity.xsl"))


  @impl true
  def tidy(xml, opts \\ []) do
    Xmllint.tidy(xml, opts)
  end

  @impl true
  def well_formed(xml, opts \\ []) do
    Xmllint.well_formed(xml, opts)
  end

  @impl true
  def validate(xml, opts \\ []) do
    Xmllint.validate(xml, opts)
  end
  
end