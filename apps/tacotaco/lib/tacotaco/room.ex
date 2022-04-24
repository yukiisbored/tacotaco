defmodule Tacotaco.Room do
  use GenServer, restart: :temporary

  @doc """
  Starts the chat room
  """
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, :ok, opts)
  end

  @doc """
  Join the chat room
  """
  def join(name, nick) do
    room = name2via(name)

    case Registry.lookup(Tacotaco.RoomRegistry, name) do
      [] -> DynamicSupervisor.start_child(Tacotaco.RoomSupervisor, {__MODULE__, name: room})
      [{pid, _}] when is_pid(pid) -> :ok
    end

    GenServer.call(room, {:join, nick})
  end

  @doc """
  Send a message to the chat room
  """
  def message(name, message) do
    wrap(name, fn room ->
      GenServer.call(room, {:message, message})
    end)
  end

  @doc """
  Leave the chat room
  """
  def part(name) do
    wrap(name, fn room ->
      GenServer.call(room, :part)
    end)
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
  def init(:ok) do
    clients = :ets.new(__MODULE__, [:private, read_concurrency: true])
    {:ok, {clients}}
  end

  @impl true
  def handle_call({:join, nick}, {client, _tag}, {clients}) do
    Process.monitor(client)
    :ets.insert(clients, {client, nick})

    broadcast(clients, {:join, nick})

    {:reply, :ok, {clients}}
  end

  @impl true
  def handle_call({:message, message}, {client, _tag}, {clients}) do
    case :ets.match(clients, {client, :"$1"}) do
      [[nick]] ->
        broadcast clients, {:message, nick, message}

        {:reply, :ok, {clients}}
      [] ->
        {:reply, {:error, :not_a_member}, {clients}}
    end
  end

  @impl true
  def handle_call(:part, {client, _tag}, {clients}) do
    case part(clients, client) do
      :ok -> {:reply, :ok, {clients}}
      :stop -> {:stop, :shutdown, :ok, {clients}}
    end
  end
  
  @impl true
  def handle_info({:DOWN, _monitor, :process, client, _reason}, {clients}) do
    case part(clients, client) do
      :ok -> {:noreply, {clients}}
      :stop -> {:stop, :shutdown, {clients}}
    end
  end

  @impl true
  def terminate(_reason, {clients}) do
	  :ets.delete(clients)
  end

  defp part(clients, client) do
    [{_, nick}] = :ets.lookup(clients, client)
    :ets.delete(clients, client)

    broadcast clients, {:part, nick}

    case :ets.first(clients) do
      :"$end_of_table" -> :stop
      _ -> :ok
    end
  end

  defp broadcast(clients, message) do
    Enum.map(:ets.tab2list(clients), fn {client, _}->
      send client, message
    end)
  end
end
