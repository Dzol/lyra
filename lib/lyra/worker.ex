defmodule Lyra.Worker do
  defstruct [:successor, :client, :predecessor]

  import GenServer, only: [start_link: 2, call: 2, reply: 2]

  ## OTP Supervision Interface

  def start_link do
    start_link(__MODULE__, [])
  end

  ## Application Interface

  def enter(vertex, oracle) when is_pid(vertex) and is_pid(oracle) do
    call(vertex, {:enter, oracle})
  end

  def exit(vertex) when is_pid(vertex) do
    call(vertex, :exit)
  end

  ## Interface for Client

  def prompt(vertex) when is_pid(vertex) do
    call(vertex, :prompt)
  end

  def query(vertex, name) when is_pid(vertex) and is_list(name) or is_binary(name) do
    call(vertex, {:successor, digest(name)})
  end

  ## Interface for Lyra

  defp prompt(client, change) when is_pid(client) do
    call(client, {:prompt, change})
  end
  defp prompt(_, _) do
    :ok
  end

  ## Generic Server Machinery Interface

  def init([]) do
    {:ok,
     %__MODULE__{} |> successor(self()) |> predecessor(self())
    }
  end

  ## These originate from outside the ring
  def handle_call(:prompt, {y, _} = x, state) do
    reply(x, :ok)
    :ok = prompt(y, segment(state))
    {:noreply, client(state, y)}
  end
  def handle_call({:enter, oracle}, _, state) do
    {:ok, p} = call(oracle, {:predecessor, point(self())})
    {:ok, s} = call(p, :successor)
    :ok = prompt(client(state), segment(state))
    :ok = call(p, {:precede, self(), unique()})
    :ok = call(s, {:succeed, self(), unique()})
    {:reply, :ok, state |> successor(s) |> predecessor(p)}
  end
  def handle_call(:exit, _, state) do
    :ok = prompt(client(state), segment(state))
    :ok = call(predecessor(state), {:precede, successor(state), unique()})
    :ok = call(successor(state), {:succeed, predecessor(state), unique()})
    {:reply, :ok, state |> successor(self())}
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
  ## These originate from inside the ring (though ultimately from outside)
  def handle_call({:precede, vertex, _}, _, state) do
    {:reply, :ok, successor(state, vertex)}
  end
  def handle_call({:succeed, vertex, _}, _, state) do
    :ok = prompt(client(state), segment(state))
    {:reply, :ok, predecessor(state, vertex)}
  end
  def handle_call(:successor, _, state) do
    {:reply, {:ok, successor(state)}, state}
  end
  def handle_call({:predecessor, subject}, _, state) do
    {:reply, predecessor(subject, self(), successor(state)), state}
  end

  ## Worker Structure Interface

  defp successor(%__MODULE__{successor: x}) do
    x
  end

  defp successor(x = %__MODULE__{}, y) do
    %{x | successor: y}
  end

  defp predecessor(%__MODULE__{predecessor: x}) do
    x
  end

  defp predecessor(x = %__MODULE__{}, y) do
    %{x | predecessor: y}
  end

  defp client(%__MODULE__{client: x}) do
    x
  end

  defp client(x = %__MODULE__{}, y) do
    %{x | client: y}
  end

  ## ADT on the Worker Structure

  defp segment(state) do
    [exclude: point(predecessor(state)), include: point(self())]
  end

  ## Ancillary

  defp predecessor(x, y, z) do
    unless Lyra.Modular.epsilon?(x, exclude: point(y), include: point(z)) do
      {:ok, successor} = call(z, :successor)
      predecessor(x, z, successor)
    else
      {:ok, y}
    end
  end

  defp point(x) when is_pid(x) do
    x
    |> identifier()
    |> digest()
  end

  defp identifier(x) do
    :erlang.pid_to_list(x)
  end

  defp digest(x) do
    :crypto.bytes_to_integer(:crypto.hash(:sha, x))
  end

  defp unique do
    ## Only on this vertex!
    make_ref()
  end
end
