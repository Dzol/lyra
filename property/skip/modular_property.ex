defmodule ModularProperty do
  use ExUnit.Case
  use EQC.ExUnit

  describe "12 o'clock is in the segment" do

    property "point outside the segment entirely (either side)" do
      scenario(wrap(), {stop(), start()}, false)
    end

    property "point inside the segment BEFORE 12 o'clock" do
      scenario(wrap(), {start(), biggest()}, true)
    end

    property "point inside the segment AFTER 12 o'clock" do
      scenario(wrap(), {zero(), stop()}, true)
    end
  end

  describe "12 o'clock is not in the segment" do

    property "point inside the segment" do
      scenario(nope(), {start(), stop()}, true)
    end

    property "point outside (BEFORE) the segment" do
      scenario(nope(), {zero(), start()}, false)
    end

    property "point outside (AFTER) the segment" do
      scenario(nope(), {stop(), biggest()}, false)
    end
  end

  property "every point inside segment (regardless of bound)" do
    forall {u = v, x} <- {bound(), point()} do
      ensure Skip.Modular.in?(u, v, x) == true
    end
  end

  ## Test Ancillaries

  def scenario(constraint, {start, stop}, outcome) do
    forall {u, v} <- bounds() do
      implies constraint.(u, v) do

        forall x <- point() do
          implies between?(x, [including: start.(u, v), excluding: stop.(u, v)]) do

            ensure Skip.Modular.in?(u, v, x) == outcome
          end
        end
      end
    end
  end

  defp wrap do
    ## Segment bounds wrap around 12 o'clock.
    fn u, v ->
      u > v
    end
  end

  defp nope do
    fn u, v ->
      u < v
    end
  end

  defp start do
    fn u, _ ->
      u
    end
  end

  defp stop do
    fn _, v ->
      v
    end
  end

  defp bounds do
    {bound(), bound()}
  end

  defp bound do
    nat()
  end

  def point do
    nat()
  end

  defp between?(x, [including: start, excluding: stop]) do
    start <= x and x < stop
  end

  def biggest do
    fn _, _ ->
      round(:math.pow(2, 160))
    end
  end

  defp zero do
    fn _, _ ->
      0
    end
  end
end
