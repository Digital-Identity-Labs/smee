defmodule Smee.XMLProcessor do

  @moduledoc """
  A flexible backend for processing XML, responsible for tidying, verify and validating XML,
  applying stylesheets and extracting reports. It acts on XML as binary strings, and is not intended to be used directly - 
    it is used via higher-level modules like `Smee.Metadata` and `Smee.Transform`.
  
  ### Selecting an XML backend

  Currently three backends are supported:

  * `:uppsala` - `Smee.XMLProcessor.Uppsala` Uses a Rust NIF embedded into Smee (the default)
  * `:libxml_tools` - `Smee.XMLProcessor.LibXMLTools` Uses external UNIX tools from the LibXML project
  * `:legacy` - `Smee.XMLProcessor.Legacy` Uses external UNIX tools from the LibXML project (deprecated)

  The active backend can be selected using a config option in your application:

  ```elixir
  # Use a shortcut name for a built-in backend
  config :smee, :xml_processor, :libxml_tools
  ```

  ```elixir
  # Specify a module directly, useful when writing your own backend
  config :smee, :xml_processor, Smee.XMLProcessor.Uppsala
  ```

  If you are happy to use the default backend (`Smee.XMLProcessor.Uppsala`) then no configuration is necessary. 
  
  """
  
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

  @doc """
  Returns the ID of the selected backend.
  
  With no options it returns the global default, set via config, but if passed options will return the ID of the backend set in the 
    options.
  """
  @spec id(opts :: keyword()) :: atom()
  def id(opts \\ []) do
    apply(backend(opts[:backend]), :id, [])
  end

  @doc """
  Returns a list of any commandline tools used by of the selected backend.
  
  If passed no options it returns the global default
  """
  @spec tools(opts :: keyword()) :: list(atom())
  def tools(opts \\ []) do
    apply(backend(opts[:backend]), :tools, [])
  end

  @doc """
  Returns the status of the selected backend.
  
  Possible statuses are `:supported`, `:experimental` and `:deprecated`
  
  If passed no options it returns the global default
  """
  @spec status(opts :: keyword()) :: atom()
  def status(opts \\ []) do
    apply(backend(opts[:backend]), :status, [])
  end

  @doc """
  Returns a friendly description of the selected backend's name, module and status
  
  If passed no options it returns the global default
  """
  @spec information(opts :: keyword()) :: binary()
  def information(opts \\ []) do
    "Active XML Processing Backend: #{id(opts)} #{if(status(opts) != :normal, do: "[#{status(opts)}]", else: "")}"
    |> String.trim()
  end

  @doc """
  Returns a map of required commandline tools and whether they are available as a boolean
  
  If passed no options it returns the global default
  """
  @spec tools_status(opts :: keyword()) :: map()
  def tools_status(opts \\ []) do
    tools(opts)
    |> Enum.map(fn tool -> if(System.find_executable(tool), do: {tool, true}, else: {tool, false}) end)
    |> Map.new()
  end

  @doc """
  Returns true if all required commandline tools are available.
    
  If no tools are actually needed it will always return true.
    
  If passed no options it returns the global default
  """
  @spec tools_ok?(opts :: keyword()) :: boolean()
  def tools_ok?(opts \\ []) do
    if Enum.empty?(tools_status(opts)) do
      true
    else
      Enum.all?(tools_status(opts), fn {_t, s} -> s == true end)
    end
  end

  @doc false
  @spec tidy(xml :: binary(), opts :: keyword()) :: {:ok, binary()} | {:error, binary()}
  def tidy(xml, opts \\ []) do
    apply(backend(opts[:backend]), :tidy, [xml, opts])
  end

  @doc false
  @spec well_formed(xml :: binary(), opts :: keyword()) :: {:ok, binary()} | {:error, binary()}
  def well_formed(xml, opts \\ []) do
    apply(backend(opts[:backend]), :well_formed, [xml, opts])
  end

  @doc false
  @spec well_formed?(xml :: binary(), opts :: keyword()) :: boolean()
  def well_formed?(xml, opts \\ []) do
    case well_formed(xml, opts) do
      {:ok, _} -> true
      {:error, _} -> false
    end
  end

  @doc false
  @spec validate(xml :: binary(), opts :: keyword()) :: {:ok, binary()} | {:error, binary()}
  def validate(xml, opts \\ []) do
    apply(backend(opts[:backend]), :validate, [xml, opts])
  end

  @doc false
  @spec validate!(xml :: binary(), opts :: keyword()) :: binary()
  def validate!(xml, opts \\ []) do
    case validate(xml, opts) do
      {:ok, result} -> result
      {:error, error} -> raise(error)
    end
  end

  @doc false
  @spec verify(xml :: binary(), certificates :: binary(), opts :: keyword()) :: {:ok, binary()} | {:error, binary()}
  def verify(xml, certificates, opts \\ []) do
    apply(backend(opts[:backend]), :verify, [xml, certificates, opts])
  end

  @doc false
  @spec verify!(xml :: binary(), certificates :: binary(), opts :: keyword()) :: binary()
  def verify!(xml, certificates, opts \\ []) do
    case verify(xml, certificates, opts) do
      {:ok, _} -> xml
      {:error, error} -> raise(error)
    end
  end

  @doc false
  @spec verify?(xml :: binary(), certificates :: binary(), opts :: keyword()) :: boolean()
  def verify?(xml, certificates, opts \\ []) do
    case verify(xml, certificates, opts) do
      {:ok, _} -> true
      {:error, _} -> false
    end
  end

  @doc false
  @spec sign(xml :: binary(), opts :: keyword()) :: {:ok, binary()} | {:error, binary()}
  def sign(xml, certificate, opts \\ []) do
    apply(backend(opts[:backend]), :sign, [xml, certificate, opts])
  end

  @doc false
  @spec transform(xml :: binary(), stylesheet :: binary(), params :: keyword(), opts :: keyword()) :: {
                                                                                                        :ok,
                                                                                                        binary()
                                                                                                      } | {
                                                                                                        :error,
                                                                                                        binary()
                                                                                                      }
  def transform(xml, stylesheet, params \\ [], opts \\ []) do
    apply(backend(opts[:backend]), :transform, [xml, stylesheet, params, opts])
  end

  @doc false
  @spec transform!(xml :: binary(), stylesheet :: binary(), params :: keyword(), opts :: keyword()) :: binary()
  def transform!(xml, stylesheet, params \\ [], options \\ []) do
    case transform(xml, stylesheet, params, options) do
      {:ok, data} -> data
      {:error, msg} -> raise msg
    end
  end

  @doc false
  @spec list_ids(xml :: binary(), opts :: keyword()) :: {:ok, list(binary())} | {:error, binary()}
  def list_ids(xml, opts \\ []) do
    apply(backend(opts[:backend]), :list_ids, [xml])
  end

  @doc false
  @spec list_ids!(xml :: binary(), opts :: keyword()) :: list(binary())
  def list_ids!(xml, opts \\ []) do
    case list_ids(xml, opts) do
      {:ok, data} -> data
      {:error, msg} -> raise(prep_msg(msg))
    end
  end

  @doc false
  @spec list_ids_compat(xml :: binary(), opts :: keyword()) :: list(binary())
  def list_ids_compat(xml, opts \\ []) do
    case list_ids(xml, opts) do
      {:ok, data} -> data
      {:error, msg} -> Logger.error("Unable to read list of entity IDs from metadata! #{msg}")
                       []
    end
  end

  @doc false
  @spec extract_entity(xml :: binary(), entity_id :: binary(), opts :: keyword()) :: {:ok, binary()} | {:ok, nil} | {
    :error,
    binary()
  }
  def extract_entity(xml, entity_id, opts \\ []) do
    apply(backend(opts[:backend]), :extract_entity, [xml, entity_id, opts])
  end

  @doc false
  @spec extract_entity!(xml :: binary(), entity_id :: binary(), opts :: keyword()) :: binary()
  def extract_entity!(xml, entity_id, opts \\ []) do
    case extract_entity(xml, entity_id, opts) do
      {:ok, nil} -> raise "Cannot find #{entity_id} in metadata!"
      {:ok, xml} -> xml
      {:error, msg} -> raise "Cannot find #{entity_id} in metadata, error occurred! #{msg}"
    end
  end

  @doc false
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

  @doc false
  @spec registered_backends() :: map()
  def registered_backends() do
    @default_registered_backends
  end

  @doc false
  @spec prep_msg(msg :: binary() | list()) :: binary()
  defp prep_msg(msg) when is_list(msg) do
    Enum.join(msg, "\n")
  end

  defp prep_msg(msg) do
    msg
  end
  
end