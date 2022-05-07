defmodule Tacotaco.Monitor do
  def listen(room, nick) do
    :ok = Tacotaco.Room.join(room, nick, self())
    loop()
  end

  defp loop() do
    IO.puts(
      receive do
        {:join, room, nick} -> "#{nick} joined #{room}."
        {:part, room, nick} -> "#{nick} left #{room}."
        {:message, room, nick, message} -> "#{room}: <#{nick}> #{message}"
      end
    )

    loop()
  end
end
