defmodule SmeeSysTest do
  use ExUnit.Case, async: false

  alias Smee.Sys
  alias Smee.SysCfg

  setup do
    on_exit(fn -> Application.put_env(:smee, :cache_dir, SysCfg.default_cache_directory()) end)
  end

  describe "reset_cache/0" do

    test "should raise an exception if passed what looks like an obviously dangerous or bad path for a cache has been configured" do
      Application.put_env(:smee, :cache_dir, "/")
      assert_raise RuntimeError, fn -> Sys.reset_cache() end
    end

    test "should return the number of files deleted in an OK tuple" do
      {:ok, cache_dir} = Briefly.create(type: :directory)
      Application.put_env(:smee, :cache_dir, cache_dir)
      Enum.each(1..5, fn n -> File.write!(Path.join(cache_dir, "test_#{n}.txt"), "Test cached file #{n}") end)
      assert {:ok, 5} = Sys.reset_cache()
    end

    test "should return zero in an OK tuple for empty cache directories" do
      {:ok, cache_dir} = Briefly.create(type: :directory)
      Application.put_env(:smee, :cache_dir, cache_dir)
      assert {:ok, 0} = Sys.reset_cache()
    end

  end

end