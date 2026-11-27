defmodule Smee.XMLProcessor.Uppsala do

  @moduledoc """
  An embedded Rust NIF backend for XML processing
  
  The default XML backend, based on the excellent Rust libraries Uppsala and Bergshamra by
  [Kushal Das](https://github.com/kushaldas) at [SUNET](https://www.sunet.se/en). Uppsala and Bergshamra are used by 
  [PyFF](https://github.com/IdentityPython/pyFF) and a few other academic SAML projects. They are actively developed, 
  well-supported and very capable libraries. When using the Uppsala backend no external tools are required,
  so Smee will work with normal LiveBooks and other systems lacking UNIX tools.
  
  ### Specifying as the default XML processing backend
  
  ```elixir
  config :smee, :xml_processor, :uppsala
  ```

  """
  
  use Smee.XMLProcessor.XMLProcessorBackend, id: :uppsala
  
  require Logger

  alias Smee.XMLProcessor.Uppsala.Native
  alias Smee.Resources

  @impl true
  def tidy(xml, _opts) do
    Native.tidy(xml)
  end

  @impl true
  def well_formed(xml, _opts) do
    case Native.well_formed(xml) do
      {:ok, _} -> {:ok, xml}
      {:error, msg} -> {:error, "Invalid XML: #{msg}"}
    end
  end

  @impl true
  def validate(xml, _opts) do
    base_schema = File.read!(Resources.saml_metadata_xml_schema_file())
    schema_dir = Resources.saml_metadata_xml_schema_dir()
    xml = String.trim(xml)
    case Native.validate(xml, base_schema, schema_dir) do
      {:ok, _validated_xml} -> {:ok, xml}
      {:error, msg} -> {:error, msg}
    end
  end

  @impl true
  def verify(xml, certificates, _opts) do
    certificates = File.read!(certificates)
    case Native.verify(xml, certificates) do
      {:ok, "true"} -> {:ok, true}
      {:ok, "false"} -> {:error, "Verification failed"}
      {:error, msg} -> {:error, msg}
    end
  end

  @impl true
  def transform(xml, stylesheet, params, _opts) do
    Native.transform(xml, stylesheet, preprocess_params(params))
  end

  @impl true
  def list_ids(xml, _opts) do
    Native.list_ids(xml)
  end

  @impl true
  def extract_entity(xml, entity_id, _opts) do
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
