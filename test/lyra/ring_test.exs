defmodule RingTest do
  use ExUnit.Case
  @size 16

  test "ONE node responsible for ALL" do

    v = unique(@size * 100)

    [ n ] = ring(1); w = world([ n ], v)

    assert Enum.count(w) === 1
    assert Enum.count(w[ n ]) == @size * 100
  end

  test "Ring nodes become responsible for LESS when nodes ENTER" do

    v = unique(@size * 100)

    r0 = ring(    div(@size, 2)); w0 = world(r0, v)
    r1 = more(r0, div(@size, 2)); w1 = world(r1, v)

    assert lattice?(w1, w0)
  end

  test "Ring nodes become responsible for MORE when nodes EXIT" do

    v = unique(@size * 100)

    r0 = ring(        @size    ); w0 = world(r0, v)
    r1 = less(r0, div(@size, 2)); w1 = world(r1, v)

    assert lattice?(w0, w1)
  end

  test "ONE remaining node responsible for ALL" do

    v = unique(@size * 100); r = ring(@size)

    [ n ] = less(r, @size - 1); w = world([ n ], v)

    assert Enum.count(w) === 1
    assert Enum.count(w[ n ]) == @size * 100
  end

  ## Ancillary

  defp unique(x) do
    for _ <- 1..x do
      :crypto.strong_rand_bytes(div(160, 8))
    end
    |> _unique()
  end

  defp ring(n) do
    more([], n)
  end

  defp more(r, n) do
    for _ <- 1..n do
      {:ok, i} = Lyra.Worker.start_link(); i
    end
    |> Enum.shuffle()
    |> Enum.reduce(r, &enter/2)
  end

  defp less(r, n) do
    r
    |> Enum.shuffle()
    |> Enum.take(n)
    |> Enum.reduce(r, &exit/2)
  end

  defp world(ring, values) do
    Enum.reduce(values, Enum.reduce(ring, %{}, &Map.put(&2, &1, [])), &resolve/2)
  end

  defp lattice?(x, y) do
    lattice?(Map.to_list(x), y, %{})
  end


  defp _unique(x) do
    (true = Enum.count(Enum.uniq(x)) === Enum.count(x)) && x
  end

  defp enter(node, []) do
    [ node ]
  end
  defp enter(node, ring) do
    :ok = Lyra.Worker.enter(node, Enum.random(ring)); [ node | ring ]
  end

  defp exit(node, ring) when ring != [] do
    :ok = Lyra.Worker.exit(node); ring -- [ node ]
  end

  defp resolve(value, partial) do
    Map.update!(partial, Lyra.Worker.resolve(Enum.random(Map.keys(partial)), value), &[ value | &1 ])
  end

  defp lattice?([], y, z) do
    sentinal?(y) and forest?(z)
  end
  defp lattice?([ {_, []} | t ], y, z) do
    lattice?(t, y, z)
  end
  defp lattice?([ h | t ], y, z) do
    i = identifier(h); v = values(h); [ p ] = parent(y, v)

    lattice?(t, Map.update!(y, p, &( &1 -- v )), Map.update(z, p, [], &[ i | &1 ]))
  end


  defp sentinal?(x) do
    Enum.all?(x, fn ({_, omega}) -> omega == [] end)
  end

  defp forest?(x) do
    Enum.all?(for({_, j} <- x, do: Enum.all?(j, &process?/1)), &i/1)
  end

  defp identifier({i, _}), do: i

  defp values({_, v}), do: v

  defp parent(x, y) do
    for {i, j} <- x, child?(y, j), do: i
  end


  defp process?(x), do: is_pid(x)

  defp i(x), do: x

  defp child?(x, y) do
    MapSet.subset?(set(x), set(y))
  end


  defp set(x) do
    MapSet.new(x)
  end
end
