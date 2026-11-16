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
