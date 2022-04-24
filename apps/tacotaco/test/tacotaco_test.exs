defmodule TacotacoTest do
  use ExUnit.Case
  doctest Tacotaco

  test "greets the world" do
    assert Tacotaco.hello() == :world
  end
end
