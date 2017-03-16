defmodule Lyra.Modular do
  @moduledoc """

  Modular arithmetic on a _(u, v]_ interval

  """
  @norm round(:math.pow(2, 160))

  @typedoc """

  An interval like _(u, v]_ in mathematics

  """
  @type interval :: [exclude: u :: integer, include: v :: integer]

  @doc """

  This is like _x ∈ (u, v]_ under modular arithmetic

  """
  @spec epsilon?(integer, interval) :: boolean
  def epsilon?(x, exclude: u, include: v) do
    _epsilon?(x, {u, v}, @norm)
  end

  @doc """

  This is the same as `epsilon?/2` but modulo _n_

  """
  @spec epsilon?(integer, interval, integer) :: boolean
  def epsilon?(x, [exclude: u, include: v], n) do
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
    distance(v, x, n) < distance(v, u, n)
  end

  ## Ancillary

  defp natural!(x) do
    true = is_integer(x) and x >= 0
  end

  defp distance(a, b, n) do
    Integer.mod(difference(b, a), n)
  end

  defp difference(a, b) do
    b - a
  end
end
