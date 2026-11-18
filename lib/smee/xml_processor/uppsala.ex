defmodule Smee.XMLProcessor.Uppsala do

  use Smee.XMLProcessor.XMLProcessorBackend, id: :uppsala

  require Logger

  alias Smee.XMLProcessor.Uppsala.Native
  alias Smee.Resources

  def tidy(xml, opts \\ []) do
    Native.tidy(xml)
  end

  def well_formed(xml, opts \\ []) do
    case Native.parse(xml) do
      {:ok, xml} -> {:ok, xml}
      {:error, msg} -> {:error, "Invalid XML: #{msg}"}
    end
  end

  def validate(xml, opts \\ []) do
    base_schema = File.read!(Resources.saml_metadata_xml_schema_file())
    schema_dir = Resources.saml_metadata_xml_schema_dir()
    xml = String.trim(xml)
    case Native.validate(xml, base_schema, schema_dir) do
      {:ok, validated_xml} -> if(opts[:return_validated], do: {:ok, validated_xml}, else: {:ok, xml})
      {:error, msg} -> {:error, msg}
    end
  end

  def verify(xml, certificates, opts \\ []) do
    certificates = File.read!(certificates)
    case Native.verify(xml, certificates) do
      {:ok, "true"} -> {:ok, true}
      {:ok, "false"} -> {:ok, false}
      {:error, msg} -> {:error, msg}
    end
  end

  def transform(xml, stylesheet, params \\ [], opts \\ []) do
    Native.transform(xml, stylesheet, preprocess_params(params))
  end

  def list_ids(xml, opts \\ []) do
    case Native.list_ids(xml) do
      {:ok, list} -> list
      {:error, _msg} ->
        Logger.error(
          "Unable to read list of entity IDs from metadata!"
        ) # Should I just raise an exception at this point?
        []
    end
  end

  def extract_entity(xml, entity_id, opts \\ []) do
    case Native.extract_entities(xml, sanitize_id!(entity_id)) do
      {:ok, []} -> {:ok, nil}
      {:ok, entities} -> {:ok, List.first(entities)}
      {:error, msg} -> {:error, "Cannot find #{entity_id} in metadata, error occurred! #{msg}"}
    end

  end

  ####################

  ## This needs to be improved but it catches at least one possible problem so better than nothing. Can Uppsala do this instead?
  defp sanitize_id!(entity_id) do
    case URI.new(entity_id) do
      {:ok, uri} -> uri = to_string(uri)
                    if(
                      String.contains?(uri, ["'", "\\"]),
                      do: raise("Invalid characters in entityID!"),
                      else: to_string(uri)
                    )
      {:error, msg} -> raise "Invalid entityID URI #{entity_id}: #{msg}"
    end
  end

  defp preprocess_params(params)

  defp preprocess_params(nil) do
    []
  end

  defp preprocess_params(params) do
    params
    |> Enum.map(fn {key, value} -> {to_string(key), to_string(value)} end)
  end

end
