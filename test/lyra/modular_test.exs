defmodule ModularTest do
  use ExUnit.Case

  test "membership in an interval like (u, v] under modular arithmetic" do
    import Lyra.Modular, only: [epsilon?: 3]
    for {x, u, v, a} <- table() do
      assert epsilon?(x, [exclude: u, include: v], norm()) == a
    end
  end

  defp norm do
    8
  end

  defp table do
    [{2, 2, 6, false},
     {4, 2, 6, true},
     {6, 2, 6, true},
     {0, 2, 6, false},
     ## Tricky interval
     {6, 6, 2, false},
     {7, 6, 2, true},
     {1, 6, 2, true},
     {2, 6, 2, true},
     {4, 6, 2, false},
     ## Tricky point
     {0, 6, 2, true},
     {8, 6, 2, true}]
  end
end
