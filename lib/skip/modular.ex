defmodule Skip.Modular do
  @moduledoc """

  Modular arithmetic of norm _2 <sup>160</sup>_ on a _[u, v)_
  interval

  **Not** general: just the above.

  """
  @norm round(:math.pow(2, 160))

  @doc """

  This is like _x ∈ [u, v)_ under modular arithmetic

  **Not** general: modular arithmetic of norm _2 <sup>160</sup>_ only.

  """
  def epsilon?(x, include: u, exclude: v) do
    natural!(x)
    natural!(u)
    natural!(v)

    if not (u === v) do
      epsilon?(x, u, v)
    else
      true
    end
  end

  defp epsilon?(x, u, v) do
    distance(u, x) < distance(u, v)
  end

  ## Ancillary

  defp natural!(x) do
    true = is_integer(x) and x >= 0
  end

  defp distance(a, b) do
    Integer.mod(difference(a, b), @norm)
  end

  defp difference(a, b) do
    b - a
  end
end
