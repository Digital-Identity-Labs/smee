defmodule Smee.XMLProcessor.Service do

  @moduledoc false
  
  use Smee.XMLProcessor.XMLProcessorBackend, id: :service, status: :experimental

  require Logger

  alias Smee.SysCfg

  @impl true
  def tidy(xml, opts \\ []) do
    with {:ok, opts} <- sanitize_opts(opts),
         {:ok, pid} <- service_pid(opts) do
      GenServer.call(pid, {:tidy, xml, opts})
    end
  end

  @impl true
  def well_formed(xml, opts \\ []) do
    with {:ok, opts} <- sanitize_opts(opts),
         {:ok, pid} <- service_pid(opts) do
      GenServer.call(pid, {:well_formed, xml, opts})
    end
  end

  @impl true
  def validate(xml, opts \\ []) do
    with {:ok, opts} <- sanitize_opts(opts),
         {:ok, pid} <- service_pid(opts) do
      GenServer.call(pid, {:validate, xml, opts})
    end
  end

  @impl true
  def verify(xml, certificates, opts \\ []) do
    with {:ok, opts} <- sanitize_opts(opts),
         {:ok, pid} <- service_pid(opts) do
      GenServer.call(pid, {:verify, xml, certificates, opts})
    end
  end

  @impl true
  def transform(xml, stylesheet, params \\ [], opts \\ []) do
    with {:ok, opts} <- sanitize_opts(opts),
         {:ok, pid} <- service_pid(opts) do
      GenServer.call(pid, {:transform, xml, stylesheet, params, opts})
    end
  end

  @impl true
  def list_ids(xml, opts \\ []) do
    with {:ok, opts} <- sanitize_opts(opts),
         {:ok, pid} <- service_pid(opts) do
      GenServer.call(pid, {:list_ids, xml, opts})
    end
  end

  @impl true
  def extract_entity(xml, entity_id, opts \\ []) do
    with {:ok, opts} <- sanitize_opts(opts),
         {:ok, pid} <- service_pid(opts) do
      GenServer.call(pid, {:extract_entity, xml, entity_id, opts})
    end
  end

  ####################

  def sanitize_opts(nil) do
    {:ok, []}
  end

  def sanitize_opts(opts) do
    {:ok, Keyword.drop(opts, [:backend])}
  end

  def service_pid(opts \\ []) do
    name = opts[:service_name] || SysCfg.xml_service_name()

    case :global.whereis_name(name) do
      :undefined -> {:error, "Cannot find an active node that has globally registered #{name} for remote XML processing"}
      found_pid -> {:ok, found_pid}
    end

  end

end
