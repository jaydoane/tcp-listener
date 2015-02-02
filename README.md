TcpListener
===========

Elixir Application that listens for TCP connections on specified port,
and writes all line-based packets (by default) to ETS table for retreival
using `TcpListener.received`.

Useful for testing TCP clients.

