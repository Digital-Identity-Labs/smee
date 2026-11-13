defmodule Smee.XMLProcessor.Uppsala do

  use Smee.XMLProcessor.XMLProcessorBackend, id: :uppsala

  require Logger

  alias Smee.XMLProcessor.Uppsala.Native

#  def tidy(xml, opts \\ []) do
#    Native.tidy(xml, opts)
#  end
#
#  def well_formed(xml, opts \\ []) do
#    Native.well_formed(xml, opts)
#  end

  def validate(xml, opts \\ []) do
    Native.validate(xml)
  end

  def verify(xml, certificates, opts \\ []) do
    Native.verify(xml, certificates)
  end

  def transform(xml, stylesheet, params, opts \\ []) do
    Native.transform(xml, stylesheet, params)
  end

  def list_ids(xml, opts \\ []) do
    Native.list_ids(xml)
  end

  def extract_entity(xml, entity_id, opts \\ []) do
    Native.extract_entity(xml, entity_id)
  end

end
