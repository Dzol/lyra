defmodule Skip.Modular do
  @norm round(:math.pow(2, 160))

  ## Value w/ more information instead of `true` or `false` something
  ## like `:more` or `:less`.

  @doc """

  This is like `x ∈ [u, v)` with modular arithmetic.

  """
  def epsilon?(x, u, v) when u > v do
    between?(x, segment(u, @norm)) or between?(x, segment(0, v))
  end
  def epsilon?(_, u, v) when u == v do
    true
  end
  def epsilon?(x, u, v) when u < v do
    between?(x, segment(u, v))
  end

  ## Ancillary

  defp between?(x, include: u, exclude: v) do
    u <= x and x < v
  end

  defp segment(a, b) do
    [include: a, exclude: b]
  end
end
