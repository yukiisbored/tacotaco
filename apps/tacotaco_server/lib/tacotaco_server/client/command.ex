defmodule TacotacoServer.Client.Command do
  def parse(line) do
    case String.split(line, " ", parts: 3, trim: true) do
      ["JOIN", room, nick] -> {:ok, {:join, room, String.trim(nick)}}
      ["PART", room] -> {:ok, {:part, String.trim(room)}}
      ["MESSAGE", room, message] -> {:ok, {:message, room, String.trim(message)}}
      _ -> {:error, :unknown_command}
    end
  end

  def run(receiver, command)

  def run(receiver, {:join, room, nick}) do
    case Tacotaco.Room.join(room, nick, receiver) do
      :ok -> {:ok, "OK\r\n"}
      {:room_created, _} -> {:ok, "OK\r\n"}
    end
  end

  def run(_, {:message, room, message}) do
    case Tacotaco.Room.message(room, message) do
      :ok -> {:ok, "OK\r\n"}
      {:error, :not_a_member} -> {:error, :not_a_member, room}
    end
  end

  def run(_, {:part, room}) do
    :ok = Tacotaco.Room.part(room)
    {:ok, "OK\r\n"}
  end
end
