defmodule LyraTest do
  use ExUnit.Case
  alias MapSet, as: Set
  @size 64

  test "On ENTRY ring nodes become responsible for LESS" do
    r = ring(nodes: 3)
    v = draw(&uniform/0, @size * 16)

    old = world(r, v)
    new = world(more(ring: r, entrants: @size - 3), v)

    consistent!(new, old)
  end

  test "On EXIT ring nodes become responsible for MORE" do
    r = ring(nodes: @size)
    v = draw(&uniform/0, @size * 16)

    old = world(r, v)
    new = world(less(ring: r, leavers: quater()), v)

    consistent!(old, new)
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

  defp more(ring: r, entrants: n) do
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

  defp ring(nodes: n) do
    ring(n)
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

  defp less(ring: r, leavers: l) when is_integer(l) do
    e = Enum.take(Enum.shuffle(r), l)
    for edge <- e do
      :ok = Lyra.Worker.exit(edge)
    end
    r -- e
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
