defmodule Skip.Modular do
  @norm round(:math.pow(2, 160))

  ## Value w/ more information instead of `true` or `false` something
  ## like `:more` or `:less`.

  @doc """

  This is like `x ∈ [u, v)` under modular arithmetic.

  """
  def epsilon?(x, include: u, exclude: v) do
    natural!(x)
    natural!(u)
    natural!(v)

    _epsilon?(x, u, v)
  end

  defp _epsilon?(x, u, v) when u > v do
    between?(x, segment(u, @norm)) or between?(x, segment(0, v))
  end
  defp _epsilon?(_, u, v) when u == v do
    true
  end
  defp _epsilon?(x, u, v) when u < v do
    between?(x, segment(u, v))
  end

  ## Ancillary

  defp between?(x, include: u, exclude: v) do
    u <= x and x < v
  end

  defp segment(a, b) do
    [include: a, exclude: b]
  end

  defp natural!(x) do
    true = is_integer(x) and x >= 0
  end
end
