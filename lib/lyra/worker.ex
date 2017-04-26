defmodule Lyra.Worker do
  @moduledoc false

  @type segment :: [exclude: start :: bound, include: stop :: bound]
  @type bound :: point
  @type point :: non_neg_integer

  defstruct [
    :identifier,
    :client,
    :successor,
    :predecessor,
    heir: []
  ]
  @type t :: %__MODULE__{
    identifier:  handle | nil,
    client:      handle | nil,
    successor:   handle | nil,
    predecessor: handle | nil,
    heir:        table  | nil
  }
  @type table  :: [handle]
  @type handle :: pid | ip4
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
     %__MODULE__{} |> identifier(i(x)) |> successor(i(x)) |> predecessor(i(x))
    }
  end

  ## These originate from outside the ring
  def handle_call(:prompt, {y, _} = x, state) do
    reply(x, :ok)
    :ok = prompt(y, segment(state))
    {:noreply, state |> client(y)}
  end
  def handle_call({:enter, oracle}, _, state) do
    {:ok, p} = @ring.predecessor(oracle, point(identifier(state)))
    {:ok, s} = @ring.successor(p)
    :ok = prompt(client(state), change(state, p))
    :ok = @ring.precede(p, identifier(state))
    :ok = @ring.succeed(s, identifier(state))
    {:reply,
     :ok,
     state
     |> successor(s)
     |> predecessor(p)
    }
  end
  def handle_call(:exit, _, state) do
    :ok = prompt(client(state), change(state, identifier(state)))
    :ok = @ring.precede(predecessor(state), successor(state))
    :ok = @ring.succeed(successor(state), predecessor(state))
    {:reply,
     :ok,
     state
     |> successor(identifier(state))
     |> predecessor(identifier(state))
    }
  end
  def handle_call({:successor, subject}, _, state) do
    {:ok, p} = predecessor(subject, identifier(state), successor(state))
    {:ok, s} = if p != identifier(state) do
      @ring.successor(p)
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
    :ok = prompt(client(state), change(state, vertex))
    {:reply, :ok, predecessor(state, vertex)}
  end
  def handle_call(:successor, _, state) do
    {:reply, {:ok, successor(state)}, state}
  end
  def handle_call({:predecessor, subject}, _, state) do
    {:reply, predecessor(subject, identifier(state), successor(state)), state}
  end

  ## Worker Structure Interface (w/ leading _)

  @spec identifier(__MODULE__.t) :: handle
  defp identifier(%__MODULE__{identifier: x}) do
    x
  end

  @spec identifier(__MODULE__.t, handle) :: __MODULE__.t
  defp identifier(x = %__MODULE__{}, y) do
    %{x | identifier: y}
  end

  @spec successor(__MODULE__.t) :: handle
  defp successor(%__MODULE__{successor: x}) do
    x
  end

  @spec successor(__MODULE__.t, handle) :: __MODULE__.t
  defp successor(x = %__MODULE__{}, y) do
    %{x | successor: y}
  end

  @spec predecessor(__MODULE__.t) :: handle
  defp predecessor(%__MODULE__{predecessor: x}) do
    x
  end

  @spec predecessor(__MODULE__.t, handle) :: __MODULE__.t
  defp predecessor(x = %__MODULE__{}, y) do
    %{x | predecessor: y}
  end

  @spec client(__MODULE__.t) :: handle
  defp client(%__MODULE__{client: x}) do
    x
  end

  @spec client(__MODULE__.t, handle) :: __MODULE__.t
  defp client(x = %__MODULE__{}, y) do
    %{x | client: y}
  end

  @spec heir(__MODULE__.t) :: table
  defp heir(%__MODULE__{heir: x}) do
    x
  end

  @spec heir(__MODULE__.t, table) :: __MODULE__.t
  defp heir(x = %__MODULE__{}, y) do
    %{x | heir: y}
  end

  ## ADT on the Worker Structure

  @spec change(__MODULE__.t, handle) :: segment
  defp change(x, y) do
    x |> predecessor(y) |> segment()
  end

  @spec segment(__MODULE__.t) :: segment
  defp segment(state) do
    [exclude: point(predecessor(state)), include: point(identifier(state))]
  end

  ## Ancillary

  @spec i([] | [interface: i :: ip4]) :: handle
  defp i([]),           do: self()
  defp i(interface: x), do: x

  @spec predecessor(point, handle, handle) :: {:ok, handle}
  defp predecessor(x, p, s) do
    alias Lyra.Modular

    if not Modular.epsilon?(x, exclude: point(p), include: point(s)) do
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
  def digest(x) do
    :crypto.bytes_to_integer(:crypto.hash(:sha, x))
  end
end
