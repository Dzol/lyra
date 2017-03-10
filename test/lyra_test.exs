defmodule LyraTest do
  use ExUnit.Case
  @size 64

  test "Nodes assume responsibility upon ring exits" do
    r = ring(@size); v = draw(&uniform/0, @size * 16)

    b = world(r, v)
    e = Enum.take(Enum.shuffle(r), div(@size, 4))
    q = r -- e
    for vertex <- e do
      :ok = Lyra.Worker.exit(vertex)
    end
    a = world(q, v)

    consistent!(b, a)
  end

  ## Ancillary

  defp draw(_, 0) do
    []
  end
  defp draw(f, n) do
    [ f.() | draw(f, n - 1) ]
  end

  defp consistent!(u, v) do
    alias MapSet, as: Set

    u = Set.new(u); v = Set.new(v)
    for i = {_, y} <- Set.difference(u, v) do
      assert Set.size(u) > Set.size(v)
      assert Enum.member?(u, i) and assumes?(v, y)
    end
  end

  defp assumes?(o, v) do
    Enum.count(Enum.reduce(o, [], who(v))) === 1
  end

  def who(v) do
    fn ({i, j}, x) ->
      if Enum.all?(v, &Enum.member?(j, &1)) do
        [i|x]
      else
        x
      end
    end
  end

  defp ring(n) when n >= 3 do
    n
    |> nodes()
    |> Enum.shuffle()
    |> ringify()
  end

  defp world(r, v) do
    world(r, v, %{})
  end

  defp world(_, [], w) do
    w
  end
  defp world(r, [x|y], w) do
    import Lyra.Worker, only: [resolve: 2]
    world(r, y, Map.update(w, resolve(select(r), x), [ x ], &[ x | &1 ]))
  end

  defp uniform do
    :crypto.strong_rand_bytes(div(160, 8))
  end

  defp nodes(0) do
    []
  end
  defp nodes(n) when n > 0 do
    [ independent() | nodes(n - 1) ]
  end

  defp ringify([ x | [ y ] ]) do ## >= 3
    :ok = Lyra.Worker.enter(y, x); [ y ]
  end
  defp ringify([ x | [ y | z ] ]) do ## z =\= []
    :ok = Lyra.Worker.enter(y, x); [ x | ringify([ y | z ]) ]
  end

  defp independent() do
    {:ok, x} = Lyra.Worker.start_link(); x
  end

  defp select(x) do
    Enum.random(x)
  end
end
