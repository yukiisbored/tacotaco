defmodule TacotacoServer.Client.Receiver do
  def start(socket) do
    loop(socket)
  end

  defp loop(socket) do
    receive do
      msg -> write(socket, msg)
    end

    loop(socket)
  end

  defp write(socket, msg)

  defp write(socket, {:join, room, nick}) do
    :gen_tcp.send(socket, "JOIN #{room} #{nick}\r\n")
  end

  defp write(socket, {:part, room, nick}) do
    :gen_tcp.send(socket, "PART #{room} #{nick}\r\n")
  end

  defp write(socket, {:message, room, nick, message}) do
    :gen_tcp.send(socket, "MESSAGE #{room} #{nick} #{message}\r\n")
  end
end
