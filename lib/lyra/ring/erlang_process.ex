defmodule Lyra.Ring.ErlangProcess do  
  import GenServer, only: [call: 2]

  @behaviour Lyra.Ring

  def precede(p, s) do
    call(p, {:precede, s, unique()})
  end

  def succeed(s, p) do
    call(s, {:succeed, p, unique()})
  end

  def predecessor(x, y) do
    call(x, {:predecessor, y})
  end

  def successor(x) do
    call(x, :successor)
  end

  defp unique do
    make_ref()
  end
end
