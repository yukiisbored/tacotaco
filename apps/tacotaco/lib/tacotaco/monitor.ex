defmodule Tacotaco.Monitor do
  def listen(room, nick) do
    :ok = Tacotaco.Room.join(room, nick)
    loop()
  end
  defp loop() do
    IO.puts(receive do
      {:join, nick} -> "#{nick} joined the room."
      {:part, nick} -> "#{nick} left the room."
      {:message, nick, message} -> "#{nick}: #{message}"
    end)

    loop()
   end
end
