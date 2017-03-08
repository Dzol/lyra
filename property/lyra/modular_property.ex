defmodule ModularProperty do
  use ExUnit.Case
  use EQC.ExUnit

  @norm round(:math.pow(2, 160))

  property "interval membership under modular arithmetic" do
    import Lyra.Modular, only: [epsilon?: 2]
    forall {u, v} <- bounds() do
      forall x <- point() do
        ensure epsilon?(x, include: u, exclude: v) == correct(x, u, v)
      end
    end
  end

  ## Our Model

  defp correct(x, u, v) when u < v do
    between?(x, include: u, exclude: v)
  end
  defp correct(_, u, v) when u === v do
    true
  end
  defp correct(x, u, v) when u > v do
    between?(x, include: u, exclude: biggest()) or between?(x, include: 0, exclude: v)
  end

  ## Test Ancillaries

  defp bounds do
    {bound(), bound()}
  end

  defp bound do
    natural()
  end

  defp point do
    natural()
  end

  defp natural do
    let i <- oneof([nat(), largeint()]) do
      if abs(i) < biggest(), do: abs(i)
    end
  end

  defp between?(x, [include: start, exclude: stop]) do
    start <= x and x < stop
  end

  def biggest do
    @norm
  end
end
