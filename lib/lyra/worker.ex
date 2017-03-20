defmodule Lyra.Worker do
  import GenServer, only: [start_link: 2, call: 2, cast: 2]

  defstruct [:successor]

  ## OTP Supervision Interface

  def start_link do
    start_link(__MODULE__, [])
  end

  ## Client Interface

  def enter(worker, ring) when is_pid(worker) and is_pid(ring) do
    call(worker, {:enter, ring})
  end

  def exit(worker) when is_pid(worker) do
    call(worker, :exit)
  end

  def resolve(worker, value) when is_pid(worker) and is_list(value) or is_binary(value) do
    call(worker, {:successor, digest(value)})
  end

  ## Generic Server Machinery Interface

  def init([]) do
    {:ok,
     %__MODULE__{successor: self()}
    }
  end

  def handle_call({:enter, ring}, _, state) do
    {:ok, p} = call(ring, {:predecessor, point(self())})
    {:ok, s} = call(p, :successor)
    :ok = call(p, {:enter, self(), unique()})
    {:reply, :ok, successor(state, s)}
  end
  def handle_call(:exit, _, state) do
    {:ok, p} = predecessor(point(self()), self(), successor(state))
    :ok = call(p, {:exit, successor(state), unique()})
    {:reply, :ok, successor(state, self())}
  end
  def handle_call({:successor, subject}, _, state) do
    {:ok, p} = predecessor(subject, self(), successor(state))
    {:ok, s} = unless p == self() do
      call(p, :successor)
    else
      {:ok, successor(state)}
    end
    {:reply, s, state}
  end
  def handle_call({x, vertex, _}, _, state) when x == :enter or x == :exit do
    {:reply, :ok, successor(state, vertex)}
  end
  def handle_call(:successor, _, state) do
    {:reply, {:ok, successor(state)}, state}
  end
  def handle_call({:predecessor, subject}, _, state) do
    {:reply, predecessor(subject, self(), successor(state)), state}
  end

  ## Ancillary

  defp predecessor(x, y, z) do
    unless Lyra.Modular.epsilon?(x, exclude: point(y), include: point(z)) do
      {:ok, successor} = call(z, :successor); predecessor(x, z, successor)
    else
      {:ok, y}
    end
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

  defp digest(x) do
    :crypto.bytes_to_integer(:crypto.hash(:sha, x))
  end

  defp identifier(x) do
    :erlang.pid_to_list(x)
  end

  defp unique do
    make_ref()
  end
end
