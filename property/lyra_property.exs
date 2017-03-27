defmodule LyraProperty do
  use ExUnit.Case
  use EQC.ExUnit
  @bits Application.fetch_env!(:lyra, :digest)[:size]

  describe "Lyra.Worker.*" do

    property "resolution to same node against a ring of three" do
      ## Given:
      {:ok, a} = Lyra.Worker.start_link()
      {:ok, b} = Lyra.Worker.start_link()
      {:ok, c} = Lyra.Worker.start_link()

      :ok = Lyra.Worker.enter(b, a)
      :ok = Lyra.Worker.enter(c, b)

      ## When:
      forall x <- natural() do
        a_ = Lyra.query(a, stringify(x))
        b_ = Lyra.query(b, stringify(x))
        c_ = Lyra.query(c, stringify(x))

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
    let i <- largebinary(div(@bits, 8)) do
      abs(:crypto.bytes_to_integer(i))
    end
  end

  defp stringify(x) when is_integer(x) do
    Integer.to_string(x)
  end
end
