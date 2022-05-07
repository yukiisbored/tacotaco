defmodule TacotacoServer.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    port = String.to_integer(System.get_env("PORT") || "1337")

    children = [
      {Task.Supervisor, name: TacotacoServer.ClientSupervisor},
      Supervisor.child_spec({Task, fn -> TacotacoServer.accept(port) end}, restart: :permanent),
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: TacotacoServer.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
