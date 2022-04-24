defmodule Tacotaco.Room do
  use GenServer, restart: :temporary

  @doc """
  Starts the chat room
  """
  def start_link(opts) do
    room_name = Keyword.fetch!(opts, :room_name)
    GenServer.start_link(__MODULE__, room_name, opts)
  end

  @doc """
  Join the chat room
  """
  def join(room, nick)

  def join(name, nick) when is_binary(name) do
    case Registry.lookup(Tacotaco.RoomRegistry, name) do
      [] ->
        with {:ok, pid} <- create_room(name),
             :ok <- join(pid, nick) do
          {:room_created, pid}
        else
          err -> err
        end

      [{pid, _}] when is_pid(pid) ->
        join(pid, nick)
    end
  end

  def join(room, nick) do
    GenServer.call(room, {:join, nick})
  end

  @doc """
  Send a message to the chat room
  """
  def message(room, message)

  def message(name, msg) when is_binary(name) do
    wrap(name, &message(&1, msg))
  end

  def message(room, message) do
    GenServer.call(room, {:message, message})
  end

  @doc """
  Leave the chat room
  """
  def part(room)

  def part(name) when is_binary(name) do
    wrap(name, &part(&1))
  end

  def part(room) do
    GenServer.call(room, :part)
  end

  defp create_room(name) do
    DynamicSupervisor.start_child(
      Tacotaco.RoomSupervisor,
      {__MODULE__, room_name: name, name: name2via(name)}
    )
  end

  defp name2via(name) do
    {:via, Registry, {Tacotaco.RoomRegistry, name}}
  end

  defp wrap(name, callback) do
    name
    |> name2via
    |> callback.()
  end

  @impl true
  def init(name) do
    clients = :ets.new(__MODULE__, [:private, read_concurrency: true])
    {:ok, {clients, name}}
  end

  @impl true
  def handle_call({:join, nick}, {client, _tag}, {clients, name}) do
    Process.monitor(client)
    :ets.insert(clients, {client, nick})

    broadcast(clients, {:join, name, nick})

    {:reply, :ok, {clients, name}}
  end

  @impl true
  def handle_call({:message, message}, {client, _tag}, {clients, name}) do
    case :ets.match(clients, {client, :"$1"}) do
      [[nick]] ->
        broadcast(clients, {:message, name, nick, message})

        {:reply, :ok, {clients, name}}

      [] ->
        {:reply, {:error, :not_a_member}, {clients, name}}
    end
  end

  @impl true
  def handle_call(:part, {client, _tag}, state) do
    case perform_part(state, client) do
      :ok -> {:reply, :ok, state}
      :stop -> {:stop, :shutdown, :ok, state}
    end
  end

  @impl true
  def handle_info({:DOWN, _monitor, :process, client, _reason}, state) do
    case perform_part(state, client) do
      :ok -> {:noreply, state}
      :stop -> {:stop, :shutdown, state}
    end
  end

  @impl true
  def terminate(_reason, {clients, _name}) do
    :ets.delete(clients)
  end

  defp perform_part({clients, name}, client) do
    [{_, nick}] = :ets.lookup(clients, client)
    :ets.delete(clients, client)

    broadcast(clients, {:part, name, nick})

    case :ets.first(clients) do
      :"$end_of_table" -> :stop
      _ -> :ok
    end
  end

  defp broadcast(clients, message) do
    Enum.map(:ets.tab2list(clients), fn {client, _} ->
      send(client, message)
    end)
  end
end
