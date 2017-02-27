defmodule SkipProperty do
  use ExUnit.Case
  use EQC.ExUnit

  @norm round(:math.pow(2, 160))

  describe "Skip.Worker.*" do
    import Skip.Worker, only: [handle_call: 3]
    property "one node always resolves to that very node" do
      forall x <- natural() do
        ensure identifier(handle_call({:resolve, x}, self(), %Skip.Worker{successor: self()})) == self()
      end
    end
  end

  ## Test Ancillaries

  defp identifier({:reply, x, %Skip.Worker{}}) do
    x
  end

  defp natural do
    let i <- oneof([nat(), largeint()]) do
      if abs(i) < biggest(), do: abs(i)
    end
  end

  def biggest do
    @norm
  end
end
