defmodule Lyra.Worker do
  defstruct [
    :identifier,
    :client,
    :successor,
    :predecessor
  ]

  import GenServer, only: [start_link: 2, call: 2, reply: 2]

  @ring Application.fetch_env!(:lyra, :ring)

  ## OTP Supervision Interface

  def start_link do
    start_link(__MODULE__, [])
  end

  def start_link(interface: x) when is_list(x) and length(x) == 4 do
    start_link(__MODULE__, [interface: x])
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

  def init(x) do
    {:ok,
     %__MODULE__{} |> _identifier(i(x)) |> _successor(i(x)) |> _predecessor(i(x))
    }
  end

  ## These originate from outside the ring
  def handle_call(:prompt, {y, _} = x, state) do
    reply(x, :ok)
    :ok = prompt(y, segment(state))
    {:noreply, state |> _client(y)}
  end
  def handle_call({:enter, oracle}, _, state) do
    {:ok, p} = @ring.predecessor(oracle, point(_identifier(state)))
    {:ok, s} = @ring.successor(p)
    :ok = prompt(_client(state), segment(state))
    :ok = @ring.precede(p, _identifier(state))
    :ok = @ring.succeed(s, _identifier(state))
    {:reply, :ok, state |> _successor(s) |> _predecessor(p)}
  end
  def handle_call(:exit, _, state) do
    :ok = prompt(_client(state), segment(state))
    :ok = @ring.precede(_predecessor(state), _successor(state))
    :ok = @ring.succeed(_successor(state), _predecessor(state))
    {:reply, :ok, state |> _successor(_identifier(state))}
  end
  def handle_call({:successor, subject}, _, state) do
    {:ok, p} = predecessor(subject, _identifier(state), _successor(state))
    {:ok, s} = unless p == _identifier(state) do
      @ring.successor(p)
    else
      {:ok, _successor(state)}
    end
    {:reply, s, state}
  end
  ## These originate from inside the ring (though ultimately from outside)
  def handle_call({:precede, vertex, _}, _, state) do
    {:reply, :ok, _successor(state, vertex)}
  end
  def handle_call({:succeed, vertex, _}, _, state) do
    :ok = prompt(_client(state), segment(state))
    {:reply, :ok, _predecessor(state, vertex)}
  end
  def handle_call(:successor, _, state) do
    {:reply, {:ok, _successor(state)}, state}
  end
  def handle_call({:predecessor, subject}, _, state) do
    {:reply, predecessor(subject, _identifier(state), _successor(state)), state}
  end

  ## Worker Structure Interface (w/ leading _)

  defp _identifier(%__MODULE__{identifier: x}) do
    x
  end

  defp _identifier(x = %__MODULE__{}, y) do
    %{x | identifier: y}
  end

  defp _successor(%__MODULE__{successor: x}) do
    x
  end

  defp _successor(x = %__MODULE__{}, y) do
    %{x | successor: y}
  end

  defp _predecessor(%__MODULE__{predecessor: x}) do
    x
  end

  defp _predecessor(x = %__MODULE__{}, y) do
    %{x | predecessor: y}
  end

  defp _client(%__MODULE__{client: x}) do
    x
  end

  defp _client(x = %__MODULE__{}, y) do
    %{x | client: y}
  end

  ## ADT on the Worker Structure

  defp segment(state) do
    [exclude: point(_predecessor(state)), include: point(_identifier(state))]
  end

  ## Ancillary

  defp i([]),           do: self()
  defp i(interface: x), do: x

  defp predecessor(x, p, s) do
    unless Lyra.Modular.epsilon?(x, exclude: point(p), include: point(s)) do
      {:ok, t} = @ring.successor(s)
      predecessor(x, s, t)
    else
      {:ok, p}
    end
  end

  defp point(x) when is_pid(x) do
    x |> listify() |> digest()
  end
  defp point(x) when is_list(x) do
    digest(x)
  end

  defp listify(x) do
    :erlang.pid_to_list(x)
  end

  defp digest(x) do
    :crypto.bytes_to_integer(:crypto.hash(:sha, x))
  end
end
