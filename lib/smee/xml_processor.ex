defmodule Smee.XMLProcessor do

  require Logger
  
  @default_registered_backends %{
    legacy: Smee.XMLProcessor.Legacy,
    uppsala: Smee.XMLProcessor.Uppsala,
    libxml_tools: Smee.XMLProcessor.LibXMLTools,
    erpc: Smee.XMLProcessor.ERPC,
    service: Smee.XMLProcessor.Service,
    http: Smee.XMLProcessor.HTTP,
  }

  alias Smee.SysCfg

  @spec id(opts :: keyword()) :: atom()
  def id(opts \\ []) do
    apply(backend(opts[:backend]), :id, [])
  end

  @spec tools(opts :: keyword()) :: list(atom())
  def tools(opts \\ []) do
    apply(backend(opts[:backend]), :tools, [])
  end

  @spec status(opts :: keyword()) :: atom()
  def status(opts \\ []) do
    apply(backend(opts[:backend]), :status, [])
  end

  @spec information(opts :: keyword()) :: binary()
  def information(opts \\ []) do
    "Active XML Processing Backend: #{id(opts)} #{if(status(opts) != :normal, do: "[#{status(opts)}]", else: "")}"
    |> String.trim()
  end

  @spec tools_status(opts :: keyword()) :: map()
  def tools_status(opts \\ []) do
    tools(opts)
    |> Enum.map(fn tool -> if(System.find_executable(tool), do: {tool, true}, else: {tool, false}) end)
    |> Map.new()
  end

  @spec tools_ok?(opts :: keyword()) :: boolean()
  def tools_ok?(opts \\ []) do
    if Enum.empty?(tools_status(opts)) do
      true
    else
      Enum.all?(tools_status(opts), fn {_t, s} -> s == true end)
    end
  end

  @spec tidy(xml :: binary(), opts :: keyword()) :: {:ok, binary()} | {:error, binary()}
  def tidy(xml, opts \\ []) do
    apply(backend(opts[:backend]), :tidy, [xml, opts])
  end

  @spec well_formed(xml :: binary(), opts :: keyword()) :: {:ok, binary()} | {:error, binary()}
  def well_formed(xml, opts \\ []) do
    apply(backend(opts[:backend]), :well_formed, [xml, opts])
  end

  @spec well_formed?(xml :: binary(), opts :: keyword()) :: boolean()
  def well_formed?(xml, opts \\ []) do
    case well_formed(xml, opts) do
      {:ok, _} -> true
      {:error, _} -> false
    end
  end
  
  @spec validate(xml :: binary(), opts :: keyword()) :: {:ok, binary()} | {:error, binary()}
  def validate(xml, opts \\ []) do
    apply(backend(opts[:backend]), :validate, [xml, opts])
  end

  @spec validate!(xml :: binary(), opts :: keyword()) :: binary()
  def validate!(xml, opts \\ []) do
    case validate(xml, opts) do
      {:ok, result} -> result
      {:error, error} -> raise(error)
    end
  end

  @spec verify(xml :: binary(), certificates :: binary(), opts :: keyword()) :: {:ok, binary()} | {:error, binary()}
  def verify(xml, certificates, opts \\ []) do
    apply(backend(opts[:backend]), :verify, [xml, certificates, opts])
  end

  @spec verify!(xml :: binary(), certificates :: binary(), opts :: keyword()) :: binary()
  def verify!(xml, certificates, opts \\ []) do
    case verify(xml, certificates, opts) do
      {:ok, _} -> xml
      {:error, error} -> raise(error)
    end
  end

  @spec verify?(xml :: binary(), certificates :: binary(), opts :: keyword()) :: boolean()
  def verify?(xml, certificates, opts \\ []) do
    case verify(xml, certificates, opts) do
      {:ok, _} -> true
      {:error, _} -> false
    end
  end

  @spec sign(xml :: binary(), opts :: keyword()) :: {:ok, binary()} | {:error, binary()}
  def sign(xml, certificate, opts \\ []) do
    apply(backend(opts[:backend]), :sign, [xml, certificate, opts])
  end

  @spec transform(xml :: binary(), stylesheet :: binary(), params :: keyword(), opts :: keyword()) :: {:ok, binary()} | {:error, binary()}
  def transform(xml, stylesheet, params \\ [], opts \\ []) do
    apply(backend(opts[:backend]), :transform, [xml, stylesheet, params, opts])
  end

  @spec transform!(xml :: binary(), stylesheet :: binary(), params :: keyword(), opts :: keyword()) :: binary()
  def transform!(xml, stylesheet, params \\ [], options \\ []) do
    case transform(xml, stylesheet, params, options) do
      {:ok, data} -> data
      {:error, msg} -> raise msg
    end
  end

  @spec list_ids(xml :: binary(), opts :: keyword()) :: {:ok, list(binary())} | {:error, binary()}
  def list_ids(xml, opts \\ []) do
    apply(backend(opts[:backend]), :list_ids, [xml])
  end

  @spec list_ids!(xml :: binary(), opts :: keyword()) :: list(binary())
  def list_ids!(xml, opts \\ []) do
    case list_ids(xml, opts) do
      {:ok, data} -> data
      {:error, msg} -> raise msg
    end
  end

  @spec list_ids_compat(xml :: binary(), opts :: keyword()) :: list(binary())
  def list_ids_compat(xml, opts \\ []) do
    case list_ids(xml, opts) do
      {:ok, data} -> data
      {:error, msg} -> Logger.error("Unable to read list of entity IDs from metadata! #{msg}")
                       []
    end
  end

  @spec extract_entity(xml :: binary(), entity_id :: binary(), opts :: keyword()) :: {:ok, binary()} | {:ok, nil} | {:error, binary()}
  def extract_entity(xml, entity_id, opts \\ []) do
    apply(backend(opts[:backend]), :extract_entity, [xml, entity_id, opts])
  end

  @spec extract_entity!(xml :: binary(), entity_id :: binary(), opts :: keyword()) :: binary()
  def extract_entity!(xml, entity_id, opts \\ []) do
    case extract_entity(xml, entity_id, opts) do
      {:ok, nil} -> raise "Cannot find #{entity_id} in metadata!"
      {:ok, xml} -> xml
      {:error, msg} -> raise "Cannot find #{entity_id} in metadata, error occurred! #{msg}"
    end
  end
  
  @spec backend(name :: binary() | atom()) :: atom()
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

  @spec registered_backends() :: map()
  def registered_backends() do
    @default_registered_backends
  end

end