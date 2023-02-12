defmodule SmeeSysCfgTest do
  use ExUnit.Case

  alias Smee.SysCfg


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


end