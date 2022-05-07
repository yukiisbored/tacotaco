defmodule TacotacoServer.Client do
  def serve(socket) do
    {:ok, receiver} = Task.start_link(fn -> TacotacoServer.Client.Receiver.start(socket) end)
    :gen_tcp.send(socket, "TACOTACO\r\n")
    loop(socket, receiver)
  end

  defp loop(socket, receiver) do
    text = with {:ok, data} <- :gen_tcp.recv(socket, 0),
                {:ok, command} <- TacotacoServer.Client.Command.parse(data),
      do: TacotacoServer.Client.Command.run(receiver, command)

    write_line(socket, text)
    loop(socket, receiver)
  end

  defp write_line(socket, text)

  defp write_line(socket, {:ok, text}) do
    :gen_tcp.send(socket, text)
  end

  defp write_line(socket, {:error, :unknown_command}) do
    :gen_tcp.send(socket, "ERR UNKNOWN COMMAND\r\n")
  end

  defp write_line(socket, {:error, :not_a_member, room}) do
	  :gen_tcp.send(socket, "ERR NOT A MEMBER #{room}\r\n")
  end

  defp write_line(_socket, {:error, :closed}) do
    exit(:shutdown)
  end

  defp write_line(socket, {:error, error}) do
    :gen_tcp.send(socket, "ERR FATAL\r\n")
	  exit(error)
  end
end
