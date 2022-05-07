defmodule TacotacoServerTest do
  use ExUnit.Case
  doctest TacotacoServer

  test "greets the world" do
    assert TacotacoServer.hello() == :world
  end
end
