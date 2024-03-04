defmodule NtcTest do
  use ExUnit.Case
  doctest Ntc

  test "greets the world" do
    assert Ntc.hello() == :world
  end
end
