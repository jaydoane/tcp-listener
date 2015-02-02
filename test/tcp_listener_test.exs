defmodule TcpListenerTest do
  use ExUnit.Case
  doctest TcpListener

  test "tcp listener can receive packets" do
    [] = TcpListener.received
    port = Application.get_env(:tcp_listener, :port)
    {:ok, socket} = :gen_tcp.connect('localhost', port, [:binary, packet: :line])
    :ok = :gen_tcp.send(socket, "testing 123\n")
    :timer.sleep 10
    1 = length(TcpListener.received)
  end
end
