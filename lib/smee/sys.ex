defmodule Smee.Sys do

  alias Smee.SysCfg
  alias Smee.Utils

  @moduledoc """
  Contains utility functions for integrating Smee with larger applications, managing caches and working files, and so on.
  """

  @doc """
  Removes **all** files from the Smee download cache.

  Unlike temporary files, download cache files will remain between runs of Smee applications, and the cache directory
    can become much too large over time. It's best to run `reset_cache/1` on application startup and maybe schedule it
   to run every few weeks too.

   The number of cache files that have been deleted will be returned in an :ok tuple.
  """
  @spec reset_cache() :: {:ok, integer()}
  def reset_cache() do
    cache_dir = SysCfg.cache_directory()
                |> Utils.check_cache_dir!()

    File.mkdir_p!(cache_dir)

    count = File.ls!(cache_dir)
            |> Enum.map(fn file -> Path.join(cache_dir, file) end)
            |> Enum.map(fn file -> File.rm_rf!(file) end)
            |> Enum.count()

    {:ok, count}
  end

  ################################################################################

end