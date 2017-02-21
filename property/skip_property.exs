defmodule SkipProperty do
  use ExUnit.Case
  use EQC.ExUnit

  property "all is well" do
    forall {m, n} <- {int(), int()} do
      implies n >= m do
        ensure :lists.seq(m, n) == Enum.to_list(m..n)
      end
    end
  end
end
