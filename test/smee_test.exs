defmodule SmeeTest do
  use ExUnit.Case
  doctest Smee

  test "greets the world" do
    assert Smee.hello() == :world
  end
end
