defmodule PromptTest do
  use ExUnit.Case

  test "prompting Lyra prompts client" do

    [ n ] = ring()

    :ok = Lyra.prompt(n)

    assert_receive {_, {^n, _}, {:prompt, [exclude: _, include: _]}}

    ## RESPOND
  end

  test "prompt on ring ENTRY" do

    import GenServer, only: [reply: 2]

    [ n ] = ring()
    [ m ] = ring()

    :ok = Lyra.prompt(n)
    :ok = Lyra.prompt(m)

    assert_receive {_, x = {^n, _}, {:prompt, [exclude: _, include: _]}}
    assert_receive {_, y = {^m, _}, {:prompt, [exclude: _, include: _]}}

    reply(x, :ok)
    reply(y, :ok)

    outcome = Task.async(merge(n, m))

    assert_receive {_, a = {^n, _}, {:prompt, [exclude: _, include: _]}}
    reply(a, :ok)
    assert_receive {_, b = {^m, _}, {:prompt, [exclude: _, include: _]}}
    reply(b, :ok)

    assert Task.await(outcome) == :success
  end

  ## Ancillary

  defp ring do
    ring(1)
  end

  defp merge(x, y) do
    fn ->
      if Lyra.Worker.enter(x, y) do
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
