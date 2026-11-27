defmodule Smee.XMLProcessor.HTTP do

  @moduledoc false
  
  use Smee.XMLProcessor.XMLProcessorBackend, id: :erpc, status: :experimental

  require Logger

  alias Smee.SysCfg

  @impl true
  def tidy(xml, opts ) do
    with {:ok, opts} <- sanitize_opts(opts),
          {:ok, node} <- service_node(opts) do
      :erpc.call(node, Smee.XMLProcessor, :tidy, [xml, opts])
    end
  end

  @impl true
  def well_formed(xml, opts) do
    with {:ok, opts} <- sanitize_opts(opts),
          {:ok, node} <- service_node(opts) do
      :erpc.call(node, Smee.XMLProcessor, :well_formed, [xml, opts])
    end
  end

  @impl true
  def validate(xml, opts) do
    with {:ok, opts} <- sanitize_opts(opts),
          {:ok, node} <- service_node(opts) do
      :erpc.call(node, Smee.XMLProcessor, :validate, [xml, opts])
    end
  end

  @impl true
  def verify(xml, certificates, opts) do
    with {:ok, opts} <- sanitize_opts(opts),
          {:ok, node} <- service_node(opts) do
      :erpc.call(node, Smee.XMLProcessor, :verify, [xml, certificates, opts])
    end
  end

  @impl true
  def transform(xml, stylesheet, params, opts) do
    with {:ok, opts} <- sanitize_opts(opts),
          {:ok, node} <- service_node(opts) do
      :erpc.call(node, Smee.XMLProcessor, :transform, [xml, stylesheet, params, opts])
    end
  end

  @impl true
  def list_ids(xml, opts) do
    with {:ok, opts} <- sanitize_opts(opts),
          {:ok, node} <- service_node(opts) do
      :erpc.call(node, Smee.XMLProcessor, :list_ids, [xml, opts])
    end
  end

  @impl true
  def extract_entity(xml, entity_id, opts) do
    with {:ok, opts} <- sanitize_opts(opts),
          {:ok, node} <- service_node(opts) do
      :erpc.call(node, Smee.XMLProcessor, :extract_entity, [xml, entity_id, opts])
    end
  end

  ####################

  def sanitize_opts(opts) do
    {:ok, Keyword.drop(opts, [:backend])}
  end

  def service_node(opts \\ []) do
    node = opts[:service_node] || SysCfg.xml_service_node()
    {:ok, node}
  end

end
