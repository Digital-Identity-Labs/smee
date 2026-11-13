defmodule Smee.XMLProcessor do

  @default_registered_backends %{
    legacy: Smee.XMLProcessor.Legacy,
    uppsala: Smee.XMLProcessor.Uppsala,
    libxml_tools: Smee.XMLProcessor.LibXMLTools,
  }

  alias Smee.SysCfg
  alias Smee.SigningCertificate

  def id(opts \\ []) do
    apply(backend(opts[:backend]), :id, [])
  end

  def tools(opts \\ []) do
    apply(backend(opts[:backend]), :tools, [])
  end

  def tidy(xml, opts \\ []) do
    apply(backend(opts[:backend]), :tidy, [xml, opts])
  end

  def well_formed(xml, opts \\ []) do
    apply(backend(opts[:backend]), :well_formed, [xml, opts])
  end

  def validate(xml, opts \\ []) do
    apply(backend(opts[:backend]), :validate, [xml, opts])
  end

  def verify(xml, certificates, opts \\ []) do
    apply(backend(opts[:backend]), :verify, [xml, certificates, opts])
  end

  def verify!(xml, certificates, opts \\ []) do
    case verify(xml, certificates, opts) do
      {:ok, result} -> result
      {:error, error} -> raise(error)
    end
  end

  def verify?(xml, certificates, opts \\ []) do
    case verify(xml, certificates, opts) do
      {:ok, _} -> true
      {:error, _} -> false
      _ -> false
    end
  end

  def sign(xml, certificate, opts \\ []) do
    apply(backend(opts[:backend]), :sign, [xml, certificate, opts])
  end

  def transform(xml, stylesheet, params \\ [], opts \\ []) do
    apply(backend(opts[:backend]), :transform, [xml, stylesheet, params, opts])
  end

  def transform!(xml, stylesheet, params \\ [], options \\ []) do
    case transform(xml, stylesheet, params, options) do
      {:ok, data} -> data
      {:error, msg} -> raise msg
    end
  end

  def list_ids(xml, opts \\ []) do
    apply(backend(opts[:backend]), :list_ids, [xml])
  end

  def extract_entity(xml, entity_id, opts \\ []) do
    apply(backend(opts[:backend]), :extract_entity, [xml, entity_id, opts])
  end

  def extract_entity!(xml, entity_id, opts \\ []) do
    case extract_entity(xml, entity_id, opts) do
      {:ok, nil} -> raise "Cannot find #{entity_id} in metadata!"
      {:ok, xml} -> xml
      {:error, msg} -> raise "Cannot find #{entity_id} in metadata, error occurred! #{msg}"
    end
  end

  def backend(name \\ SysCfg.xml_processor())

  def backend(name) when is_nil(name) do
    backend()
  end

  def backend(name) when is_binary(name) do
    String.to_existing_atom(name)
    |> backend()
  end

  def backend(name) when is_atom(name) do
    Map.get(registered_backends(), name) || name
  end

  def registered_backends() do
    @default_registered_backends
  end

end