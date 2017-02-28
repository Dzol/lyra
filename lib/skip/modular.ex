defmodule Skip.Modular do
  @moduledoc """

  Modular arithmetic of norm _2 <sup>160</sup>_ on a _[u, v)_
  interval

  **Not** general: just the above.

  """
  @norm round(:math.pow(2, 160))

  @doc """

  This is like _x ∈ [u, v)_ under modular arithmetic

  """
  def epsilon?(x, include: u, exclude: v) do
    _epsilon?(x, {u, v}, @norm)
  end

  def epsilon?(x, [include: u, exclude: v], n) do
    _epsilon?(x, {u, v}, n)
  end

  defp _epsilon?(x, {u, v}, n) do
    natural!(x); natural!(u); natural!(v)

    if not (u === v) do
      epsilon?(x, u, v, n)
    else
      true
    end
  end

  defp epsilon?(x, u, v, n) do
    distance(u, x, n) < distance(u, v, n)
  end

  ## Ancillary

  defp natural!(x) do
    true = is_integer(x) and x >= 0
  end

  defp distance(a, b, n) do
    Integer.mod(difference(a, b), n)
  end

  defp difference(a, b) do
    b - a
  end
end
