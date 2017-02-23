defmodule Skip.Modular do
  @norm round(:math.pow(2, 160))

  ## Just a boolean expression spelled out with functions?  Generalize
  ## w/ inclusion + exclusion (and macro). Value w/ more information
  ## instead of `true` or `false` something like `:more` or `:less`.
  def in?(u, v, x) when u > v do
    cond do
      u <= x and x < @norm ->
        true
      0 <= x and x < v ->
        true
      v <= x and x < u ->
        false
    end
  end
  def in?(u, v, _) when u == v do
    true
  end
  def in?(u, v, x) when u < v do
    cond do
      u <= x and x < v ->
        true
      v <= x or x < u ->
        false
    end
  end
end
