defmodule SmeeXmlCfgTest do
  use ExUnit.Case

  alias Smee.XmlCfg

  describe "default_namespace/0" do

    test "should default to :md" do
      assert :md = XmlCfg.default_namespace()
    end

  end

  describe "namespaces/0" do

    test "should return a map" do
      assert %{} = XmlCfg.namespaces()
    end

    # ...

  end

  describe "risky_entity_attributes/0" do

    test "should return a list" do
      assert is_list(XmlCfg.risky_entity_attributes())
    end

    # ...

  end

end