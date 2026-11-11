defmodule Smee.XMLProcessor.Uppsala.Native do

use Rustler, otp_app: :smee, crate: "uppsala_xml_processor"

## When the NIF is loaded these functions will be overloaded with native equivalents
def parse(_string), do: :erlang.nif_error(:nif_not_loaded)
def validate(_xml, _schema), do: :erlang.nif_error(:nif_not_loaded)
def verify(_xml, _cert), do: :erlang.nif_error(:nif_not_loaded)
def transform(_xml, _xslt), do: :erlang.nif_error(:nif_not_loaded)
def list_ids(_xml), do: :erlang.nif_error(:nif_not_loaded)
def extract_entities(_xml,_entity_id), do: :erlang.nif_error(:nif_not_loaded)
  
end
