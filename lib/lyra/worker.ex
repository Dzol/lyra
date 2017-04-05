defmodule Lyra.Worker do
  @type segment :: [exclude: start :: bound, include: stop :: bound]
  @type bound :: point
  @type point :: non_neg_integer

  defstruct [
    :identifier,
    :client,
    :successor,
    :predecessor
  ]
  @type t :: %__MODULE__{
    identifier:  handle,
    client:      handle,
    successor:   handle,
    predecessor: handle
  }
  @type handle :: pid | ip4 | nil
  @type ip4    :: [byte]

  import GenServer, only: [start_link: 2, call: 2, reply: 2]

  @ring Application.fetch_env!(:lyra, :ring)

  ## OTP Supervision Interface

  @spec start_link() :: GenServer.on_start
  def start_link do
    start_link(__MODULE__, [])
  end

  @spec start_link(interface: i :: ip4) :: GenServer.on_start
  def start_link(interface: x) when is_list(x) and length(x) == 4 do
    start_link(__MODULE__, [interface: x])
  end

  ## Application Interface

  @spec enter(local :: handle, remote :: handle) :: :ok
  def enter(vertex, oracle) when is_pid(vertex) and is_pid(oracle) do
    call(vertex, {:enter, oracle})
  end

  @spec exit(local :: handle) :: :ok
  def exit(vertex) when is_pid(vertex) do
    call(vertex, :exit)
  end

  ## Interface for Client

  @spec prompt(local :: handle) :: :ok
  def prompt(vertex) when is_pid(vertex) do
    call(vertex, :prompt)
  end

  @spec query(local :: handle, iodata) :: remote :: handle
  def query(vertex, name) when is_pid(vertex) and is_list(name) or is_binary(name) do
    call(vertex, {:successor, digest(name)})
  end

  ## Interface for Lyra

  @spec prompt(local :: handle, segment) :: :ok
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

  @spec _identifier(__MODULE__.t) :: handle
  defp _identifier(%__MODULE__{identifier: x}) do
    x
  end

  @spec _identifier(__MODULE__.t, handle) :: __MODULE__.t
  defp _identifier(x = %__MODULE__{}, y) do
    %{x | identifier: y}
  end

  @spec _successor(__MODULE__.t) :: handle
  defp _successor(%__MODULE__{successor: x}) do
    x
  end

  @spec _successor(__MODULE__.t, handle) :: __MODULE__.t
  defp _successor(x = %__MODULE__{}, y) do
    %{x | successor: y}
  end

  @spec _predecessor(__MODULE__.t) :: handle
  defp _predecessor(%__MODULE__{predecessor: x}) do
    x
  end

  @spec _predecessor(__MODULE__.t, handle) :: __MODULE__.t
  defp _predecessor(x = %__MODULE__{}, y) do
    %{x | predecessor: y}
  end

  @spec _client(__MODULE__.t) :: handle
  defp _client(%__MODULE__{client: x}) do
    x
  end

  @spec _client(__MODULE__.t, handle) :: __MODULE__.t
  defp _client(x = %__MODULE__{}, y) do
    %{x | client: y}
  end

  ## ADT on the Worker Structure

  @spec segment(__MODULE__.t) :: segment
  defp segment(state) do
    [exclude: point(_predecessor(state)), include: point(_identifier(state))]
  end

  ## Ancillary

  @spec i([] | [interface: i :: ip4]) :: handle
  defp i([]),           do: self()
  defp i(interface: x), do: x

  @spec predecessor(point, handle, handle) :: {:ok, handle}
  defp predecessor(x, p, s) do
    unless Lyra.Modular.epsilon?(x, exclude: point(p), include: point(s)) do
      {:ok, t} = @ring.successor(s)
      predecessor(x, s, t)
    else
      {:ok, p}
    end
  end

  @spec point(handle) :: integer
  defp point(x) when is_pid(x) do
    x |> listify() |> digest()
  end
  defp point(x) when is_list(x) do
    digest(x)
  end

  @spec listify(pid) :: charlist
  defp listify(x) do
    :erlang.pid_to_list(x)
  end

  @spec digest(iodata) :: integer
  defp digest(x) do
    :crypto.bytes_to_integer(:crypto.hash(:sha, x))
  end
end
