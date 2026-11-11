defmodule Smee.XMLProcessor do

  @default_registered_backends %{
    legacy: Smee.XMLProcessor.Legacy,
    uppsala: Smee.XMLProcessor.Uppsala,
    libxml_tools: Smee.XMLProcessor.LibXMLTools,
  }

  alias Smee.SysCfg

  def id(opts \\ []) do
    apply(backend(opts[:backend]), :id, [])
  end

  def tools(opts \\ []) do
    apply(backend(opts[:backend]), :tools, [])
  end
  
  def whatever(params, opts \\ []) do
    apply(backend(opts[:backend]), :verify!, [params])
  end

  
#  @callback  check_requirements() :: :ok | {:error, binary()}
#  @callback  config() :: keyword()
#
#  @callback  tidy(xml :: binary(), options :: keyword()) :: {:ok, binary()} | {:error, binary()}
#  @callback  well_formed(xml :: binary(), options :: keyword()) :: {:ok, binary()} | {:error, binary()}
#  @callback  validate(xml :: binary(), schema :: binary(), options :: keyword()) :: {:ok, binary()} | {:error, binary()}
#  @callback  verify(xml :: binary(), certificates :: binary(), options :: keyword()) :: {:ok, binary()} | {:error, binary()}
#  @callback  sign(xml :: binary(), certificate :: binary(), options :: keyword()) :: {:ok, binary()} | {:error, binary()}
#  @callback  transform(xml :: binary(),  stylesheet :: binary(), options :: keyword()) :: {:ok, binary()} | {:error, binary()}



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

  ##################

  

end