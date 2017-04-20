defmodule Lyra.Ring.ErlangProcess do
  @moduledoc """
  And Erlang process ring.
  """
  import GenServer, only: [call: 2]

  @behaviour Lyra.Ring

  @spec precede(pid, pid) :: :ok
  def precede(p, s) do
    call(p, {:precede, s, unique()})
  end

  @spec succeed(pid, pid) :: :ok
  def succeed(s, p) do
    call(s, {:succeed, p, unique()})
  end

  @spec predecessor(pid, Lyra.Worker.point) :: {:ok, pid}
  def predecessor(x, y) do
    call(x, {:predecessor, y})
  end

  @spec successor(pid) :: {:ok, pid}
  def successor(x) do
    call(x, :successor)
  end

  @spec unique() :: reference
  defp unique do
    make_ref()
  end
end
