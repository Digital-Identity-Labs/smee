defmodule Smee.XMLServer do

  @moduledoc false
  
  use GenServer
  
  alias Smee.SysCfg
  alias Smee.XMLProcessor
  
  @impl true
  def init(global_opts) do
    {:ok, global_opts}
  end

  @impl true
  def handle_call(:hello, from, state) do
    {:reply, "hello", state}
  end

  @impl true
  def handle_call({:tidy, xml, opts}, _from, state) do
    with {:ok, opts} <- sanitize_opts(opts) do
      {:reply, XMLProcessor.tidy(xml, opts), state}
    end
  end

  @impl true
  def handle_call({:well_formed, xml, opts}, _from, state) do
    with {:ok, opts} <- sanitize_opts(opts) do
      {:reply, XMLProcessor.well_formed(xml, opts), state}
    end
  end

  @impl true
  def handle_call({:validate, xml, opts}, _from, state) do
    with {:ok, opts} <- sanitize_opts(opts) do
      {:reply, XMLProcessor.validate(xml, opts), state}
    end
  end
  
  @impl true
  def handle_call({:verify, xml, certificates, opts}, _from, state) do
    with {:ok, opts} <- sanitize_opts(opts) do
      {:reply, XMLProcessor.verify(xml, certificates, opts), state}
    end
  end  
  
  @impl true
  def handle_call({:transform, xml, stylesheet, params, opts}, _from, state) do
    with {:ok, opts} <- sanitize_opts(opts) do
      {:reply, XMLProcessor.transform(xml, stylesheet, params, opts), state}
    end
  end 
  
  @impl true
  def handle_call({:list_ids, xml, opts}, _from, state) do
    with {:ok, opts} <- sanitize_opts(opts) do
      {:reply, XMLProcessor.list_ids(xml, opts), state}
    end
  end

  @impl true
  def handle_call({:extract_entity, xml, entity_id, opts}, _from, state) do
    with {:ok, opts} <- sanitize_opts(opts) do
      {:reply, XMLProcessor.extract_entity(xml, entity_id, opts), state}
    end
  end

  def handle_call(msg, from, state) do
    {:reply, {:error, "Unknown message received by XMLServer!"}, state}
  end
  
  def sanitize_opts(nil) do
    []
  end
  
  def sanitize_opts(opts) do
    if opts[:backend] in [:service, nil] do
      {:ok, Keyword.put(opts, :backend, :uppsala)}
    else
      {:ok, Keyword.drop(opts, [:backend])}
    end
  end
  
end