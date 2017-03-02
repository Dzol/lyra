defmodule SkipProperty do
  use ExUnit.Case
  use EQC.ExUnit

  describe "Skip.Worker.*" do
    alias Skip.Worker, as: Node

    property "resolution to same node against a ring of three" do
      ## Given:
      {:ok, a} = Node.start_link()
      {:ok, b} = Node.start_link()
      {:ok, c} = Node.start_link()

      :ok = Node.enter(b, a)
      :ok = Node.enter(c, b)

      ## When:
      forall x <- natural() do
        a_ = Node.resolve(a, stringify(x))
        b_ = Node.resolve(b, stringify(x))
        c_ = Node.resolve(c, stringify(x))

        collect a: a_, b: b_, c: c_ do

          ## Then:
          ensure a_ == b_
          ensure b_ == c_
        end
      end
    end
  end

  ## Test Ancillaries

  defp natural do
    let i <- largebinary(div(160, 8)) do
      abs(:crypto.bytes_to_integer(i))
    end
  end

  defp stringify(x) when is_integer(x) do
    Integer.to_string(x)
  end
end
