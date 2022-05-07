# Tacotaco

This is a simple multi-room chat server written in Elixir. This project is
created to simply teach myself Elixir/Erlang/BEAM.

The `Tacotaco.Room` has a rather awkward client code. This is mainly because I
mainly play around with it through `iex` (hence why before `bf25285`, the
receiver and sender PID are expected to be the same).

If I make a rewrite of Tacotaco, I'd write it in a more agnostic fashion for any
"server" implementation (i.e TCP, UDP, Websocket) and write a proper "room name
to room pid" router module instead of abusing `via` which actually checks if the
room process exist.

`TacotacoServer` is hastily written and isn't well tested. However, it
demonstrates the beauty of BEAM's "let it crash" philosophy, so there's that.

Anyway, have fun reading the janky code.
