defmodule SmeeSysCfgTest do
  use ExUnit.Case, async: false

  alias Smee.SysCfg

  setup do
    on_exit(fn -> Application.put_env(:smee, :cache_dir, SysCfg.default_cache_directory()) end)
  end

  describe "strategies/0" do

    test "returns list of atoms" do
      Enum.each(SysCfg.strategies, fn s -> assert is_atom(s) end)
    end

    test "returns :pragmatic, :fast, :small, and :standalone" do
      strats = SysCfg.strategies()
      assert Enum.member?(strats, :pragmatic)
      assert Enum.member?(strats, :fast)
      assert Enum.member?(strats, :small)
      assert Enum.member?(strats, :standalone)
    end

  end

  describe "strategy/0" do

    test "should default to pragmatic" do
      assert :pragmatic = SysCfg.strategy
    end

  end

  describe "security_backend/0" do

    test "should default to Smee.Security.Xmlsec1" do
      assert Smee.Security.Xmlsec1 = SysCfg.security_backend()
    end

  end

  describe "cache_directory/0" do

    test "should default to the value of default_cache_directory/0" do
      default_directory = SysCfg.default_cache_directory()
      assert ^default_directory = SysCfg.cache_directory()
    end

    test "should be changeable using a config option" do
      Application.put_env(:smee, :cache_dir, "/tmp/example_smee_cache")
      assert "/tmp/example_smee_cache" = SysCfg.cache_directory()
    end
  end

  describe "default_cache_directory/0" do

    test "should be a 'smee' directory that is inside the system user cache directory (differs depending on OS and OTP)" do
      default_directory = :filename.basedir(:user_cache, "smee")
      assert ^default_directory = SysCfg.default_cache_directory()
    end

  end

end
