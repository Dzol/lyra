defmodule PromptTest do
  use ExUnit.Case

  test "prompting Lyra prompts client" do

    [ n ] = ring()

    :ok = Lyra.prompt(n)

    assert_receive {_, {^n, _}, {:prompt, [exclude: _, include: _]}}

    ## RESPOND
  end

  test "prompt on ring ENTRY and EXIT" do

    import GenServer, only: [reply: 2]

    [ i ] = ring()
    [ j ] = ring()
    [ k ] = ring()

    :ok = Lyra.prompt(i)
    :ok = Lyra.prompt(j)
    :ok = Lyra.prompt(k)
    assert_receive {_, x = {^i, _}, {:prompt, s0 = [exclude: _, include: _]}}
    assert_receive {_, y = {^j, _}, {:prompt, t0 = [exclude: _, include: _]}}
    assert_receive {_, z = {^k, _}, {:prompt, u0 = [exclude: _, include: _]}}
    refute s0 == t0
    refute t0 == u0
    refute u0 == s0
    reply(x, :ok)
    reply(y, :ok)
    reply(z, :ok)

    outcome = Task.async(merge(j, i))
    assert_receive {_, a = {^j, _}, {:prompt, t1 = [exclude: _, include: _]}}
    refute t0 == t1
    reply(a, :ok)
    assert_receive {_, b = {^i, _}, {:prompt, s1 = [exclude: _, include: _]}}
    refute s0 == s1
    reply(b, :ok)
    assert Task.await(outcome) == :success

    outcome = Task.async(merge(k, j))
    assert_receive {_, c = {^k, _}, {:prompt, u1 = [exclude: _, include: _]}}
    refute u0 == u1
    reply(c, :ok)
    assert_receive {_, d = {l, _}, {:prompt, [exclude: _, include: _]}}
    reply(d, :ok)
    assert successor(k) == l
    assert Task.await(outcome) == :success

    outcome = Task.async(split(i))
    m = successor(i)
    assert_receive {_, e = {^i, _}, {:prompt, s2 = [exclude: _, include: _]}}
    assert s0 == s2
    reply(e, :ok)
    assert_receive {_, f = {^m, _}, {:prompt, [exclude: _, include: _]}}
    reply(f, :ok)
    assert Task.await(outcome) == :success
  end

  ## Ancillary

  defp successor(x) do
    _successor(:sys.get_state(x))
  end

  defp _successor(%Lyra.Worker{successor: x}) do
    x
  end

  defp ring do
    ring(1)
  end

  defp merge(x, y) do
    fn ->
      if Lyra.Worker.enter(x, y) == :ok do
        :success
      else
        :failure
      end
    end
  end

  defp split(x) do
    fn ->
      if Lyra.Worker.exit(x) == :ok do
        :success
      else
        :failure
      end
    end
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

  defp enter(node, []) do
    [ node ]
  end
  defp enter(node, ring) do
    :ok = Lyra.Worker.enter(node, Enum.random(ring)); [ node | ring ]
  end
end
