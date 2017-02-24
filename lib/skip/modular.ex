defmodule Skip.Modular do
  @moduledoc """

  Modular arithmetic on some intervals.

  """
  @norm round(:math.pow(2, 160))

  @doc """

  This is like `x ∈ [u, v)` under modular arithmetic.

  """
  def epsilon?(x, include: u, exclude: v) do
    natural!(x)
    natural!(u)
    natural!(v)

    epsilon?(x, u, v)
  end

  defp epsilon?(x, u, v) do
    distance(u, x) < distance(u, v)
  end

  ## Ancillary

  defp distance(a, b) do
    Integer.mod((b - a), @norm)
  end

  defp natural!(x) do
    true = is_integer(x) and x >= 0
  end
end
