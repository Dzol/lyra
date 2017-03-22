defmodule PromptTest do
  use ExUnit.Case

  test "prompting Lyra prompts client" do

    [ n ] = ring(1)

    :ok = Lyra.prompt(n)

    assert_receive {_, {^n, _}, [exclude: _, include: _]}
  end

  ## Ancillary

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
