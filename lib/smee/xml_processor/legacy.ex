defmodule Smee.XMLProcessor.Legacy do

  use Smee.XMLProcessor.XMLProcessorBackend, id: :legacy, tools: ["xmllint", "xsltproc", "xmlsec1"]

  require Logger

  alias Smee.XMLProcessor.Legacy.Xmllint
  alias Smee.XMLProcessor.Legacy.Xmlsec1
  alias Smee.XMLProcessor.Legacy.Xsltproc

  @list_ids_s File.read!(Application.app_dir(:smee, "priv/xslt/list_ids.xsl"))
  @entity_s File.read!(Application.app_dir(:smee, "priv/xslt/extract_entity.xsl"))
  
  def tidy(xml, opts \\ []) do
    Xmllint.tidy(xml, opts)
  end

  def well_formed(xml, opts \\ []) do
    Xmllint.well_formed(xml, opts)
  end

  def validate(xml, opts \\ []) do
    Xmllint.validate(xml, opts)
  end

  def verify(xml, certificates, opts \\ []) do
    Xmlsec1.verify(xml, certificates, opts)
  end

  def transform(xml, stylesheet, params, opts \\ []) do
    Xsltproc.transform(xml, stylesheet, params, opts)
  end

  def list_ids(xml, opts \\ []) do
    case transform(xml, @list_ids_s, []) do
      {:ok, txt} -> String.split(txt)
      {:error, _msg} ->
        Logger.error(
          "Unable to read list of entity IDs from metadata!"
        ) # Should I just raise an exception at this point?
        []
    end
  end

  def extract_entity(xml, entity_id, opts \\ []) do
    case transform(xml, @entity_s, entityID: entity_id) do
      {:ok, nil} -> {:ok, nil}
      {:ok, ""} -> {:ok, nil}
      {:ok, xml} -> {:ok, xml}
      {:error, msg} -> {:error, "Cannot find #{entity_id} in metadata, error occurred! #{msg}"}
    end
  end

end