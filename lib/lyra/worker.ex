defmodule Lyra.Worker do
  use GenServer

  defstruct [:successor]

  ## OTP Supervision Interface

  def start_link do
    GenServer.start_link(__MODULE__, [])
  end

  ## Client Interface

  def enter(worker, ring) when is_pid(worker) and is_pid(ring) do
    GenServer.call(worker, {:enter, ring})
  end

  def exit(worker) when is_pid(worker) do
    GenServer.call(worker, :exit)
  end

  def resolve(worker, value) when is_pid(worker) and is_list(value) or is_binary(value) do
    GenServer.call(worker, {:find_successor, digest(value)})
  end

  ## Ring Interface

  def find_successor(worker, node) when is_pid(worker) and is_pid(node) do # Find
    GenServer.call(worker, {:find_successor, point(node)})
  end
  def find_successor(worker, value) when is_pid(worker) and is_list(value) or is_binary(value) do
    GenServer.call(worker, {:find_successor, digest(value)})
  end
  def find_successor(worker, value) when is_pid(worker) and is_integer(value) do
    GenServer.call(worker, {:find_successor, value})
  end

  def find_predecessor(worker, node) when is_pid(worker) and is_pid(node) do # Find
    GenServer.call(worker, {:find_predecessor, point(node)})
  end
  def find_predecessor(worker, value) when is_pid(worker) and is_list(value) or is_binary(value) do
    GenServer.call(worker, {:find_predecessor, digest(value)})
  end
  def find_predecessor(worker, value) when is_pid(worker) and is_integer(value) do
    GenServer.call(worker, {:find_predecessor, value})
  end

  ## Generic Server Machinery Interface

  def init([]) do
    {:ok,
     %__MODULE__{successor: self()}
    }
  end

  def handle_call({:find_successor, subject}, _, state) do
    alias GenServer, as: Server

    {:ok, p} = predecessor(subject, self(), successor(state))
    {:ok, s} = unless p == self() do
      Server.call(p, :successor)
    else
      {:ok, successor(state)}
    end
    {:reply, s, state}
  end
  def handle_call({:find_predecessor, subject}, _, state) do
    {:reply, predecessor_query(successor(state), subject), state}
  end
  def handle_call(:successor, _, state) do
    {:reply, {:ok, successor(state)}, state}
  end
  def handle_call({:enter, ring}, _, state) do
    {p, s} = older_siblings(ring)
    send(p, {:enter, self(), unique()})
    {:reply, :ok, successor(state, s)}
  end
  def handle_call(:exit, _, state) do
    {:ok, p} = predecessor(point(self()), self(), successor(state))
    send(p, {:exit, successor(state), unique()})
    {:reply, :ok, successor(state, self())}
  end

  def handle_info({x, vertex, _}, state) when x == :enter or x == :exit do
    {:noreply, successor(state, vertex)}
  end

  ## Ancillary

  defp predecessor(x, y, z) do
    hop(x, y, z)
  end

  defp hop(x, y, z) do
    alias GenServer, as: Server

    if not between?(x, y, z) do
      {:ok, successor} = Server.call(z, :successor); hop(x, z, successor)
    else
      {:ok, y}
    end
  end

  defp older_siblings(ring) do
    {find_predecessor(ring, self()), find_successor(ring, self())}
  end

  defp predecessor_query(successor, subject) do
    if between?(subject, self(), successor) do
      self()
    else
      find_predecessor(successor, subject)
    end
  end

  defp between?(x, y, z) do
    Lyra.Modular.epsilon?(x, exclude: point(y), include: point(z))
  end

  defp successor(%__MODULE__{successor: x}) do
    x
  end

  defp successor(x = %__MODULE__{}, y) do
    %{x | successor: y}
  end

  defp point(x) when is_pid(x) do
    x
    |> identifier()
    |> digest()
  end

  defp digest(x) when is_list(x) or is_binary(x) do
    :crypto.bytes_to_integer(:crypto.hash(:sha, x))
  end

  defp identifier(x) when is_pid(x) do
    :erlang.pid_to_list(x)
  end

  defp unique do
    make_ref()
  end
end
