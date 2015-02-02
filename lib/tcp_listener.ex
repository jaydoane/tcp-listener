defmodule TcpListener do
  use Application
  require Logger

  @moduledoc """
  Listen for TCP connections on specified port, and write all line-based packets
  to ETS table for retreival using `TcpListener.received`.  Useful for testing TCP clients.
  """

  @app :tcp_listener

  @default_port 2003
  @default_tcp_opts [:binary, packet: :line, active: false, reuseaddr: :true]

  def start(_type, _args) do
    info "start"
    ets = :ets.new(@app, [:named_table, :duplicate_bag, :public])
    info "start new ets #{inspect ets}"

    port = Application.get_env(@app, :port, @default_port)
    tcp_opts = Application.get_env(@app, :tcp_opts, @default_tcp_opts)
    info "start port #{port} tcp_opts #{inspect tcp_opts}"

    import Supervisor.Spec
    children = [
      supervisor(Task.Supervisor, [[name: TcpListener.TaskSupervisor]]),
      worker(Task, [TcpListener, :accept, [port, tcp_opts]])
    ]

    opts = [strategy: :one_for_one, name: TcpListener.Supervisor]
    Supervisor.start_link(children, opts)
  end

  @doc """
  Return the list of packets received by the server
  """
  def received() do
    for {:received, packet} <- :ets.lookup(@app, :received), do: packet
  end

  @doc """
  Start accepting connections on the given `port`.
  """
  def accept(port, tcp_opts) do
    {:ok, listen_socket} = :gen_tcp.listen(port, tcp_opts)
    info "accept listen_socket: #{inspect listen_socket}"
    loop_acceptor(listen_socket)
  end

  defp loop_acceptor(listen_socket) do
    {:ok, socket} = :gen_tcp.accept(listen_socket) # block until client connects
    info "loop_acceptor open socket #{inspect socket}"
    Task.Supervisor.start_child(TcpListener.TaskSupervisor, fn -> serve(socket) end)
    loop_acceptor(listen_socket)
  end

  defp serve(socket) do
    case blocking_read_line(socket) do
      {:error, reason} ->
        info "serve tcp error #{reason}"
        :ok
      {:ok, packet} ->
        debug "serve tcp recv #{packet}"
        :true = :ets.insert(@app, {:received, packet})
        serve(socket)
    end
  end

  defp blocking_read_line(socket) do :gen_tcp.recv(socket, 0) end
  
  defp info(msg) do  Logger.info("#{inspect __MODULE__}." <> msg) end
  defp debug(msg) do  Logger.debug("#{inspect __MODULE__}." <> msg) end
end
