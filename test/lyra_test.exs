defmodule LyraTest do
  use ExUnit.Case
  alias MapSet, as: Set
  @size 64

  test "Ring nodes responsible for LESS upon ENTRY" do
    r = ring(3); v = draw(&uniform/0, @size * 16)

    b = world(r, v)
    a = world(more(r, @size - 3), v)

    consistent!(a, b)
  end

  test "Ring nodes responsible for MORE upon EXIT" do
    r = ring(@size); v = draw(&uniform/0, @size * 16)

    b = world(r, v)
    e = Enum.take(Enum.shuffle(r), quater())
    for edge <- e do
      :ok = Lyra.Worker.exit(edge)
    end
    a = world(r -- e, v)

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
    for i = {_, y} <- Set.difference(u, v) do
      assert Set.size(u) > Set.size(v)
      assert Enum.member?(u, i)
      assert Enum.count(buckets(v, y)) === 1
    end
  end

  defp buckets(o, v) do
    Enum.reduce(o, [], bucket(v))
  end

  defp bucket(v) do
    fn ({i, j}, x) ->
      cond do
        Enum.all?(v, &Enum.member?(j, &1)) ->
          [i|x]
        Enum.any?(v, &Enum.member?(j, &1)) ->
          [i|x]
        true ->
          x
      end
    end
  end

  defp more(r, n) do
    m = n
    |> nodes()
    |> Enum.shuffle()
    ringify(r, m)
  end

  defp ringify(_, []) do
    []
  end
  defp ringify(r, [n|more]) do
    :ok = Lyra.Worker.enter(n, select(r)); [ n | ringify(r, more) ]
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
    Set.new(w)
  end
  defp world(r, [x|y], w) do
    import Lyra.Worker, only: [resolve: 2]
    world(r, y, Map.update(w, resolve(select(r), x), [ x ], &[ x | &1 ]))
  end

  defp quater do
    div(@size, 4)
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
