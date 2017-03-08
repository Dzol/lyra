defmodule Lyra.Application do
  @moduledoc false

  use Application

  def start(_, _) do
    import Supervisor.Spec, warn: false

    opts = [strategy: :one_for_one, name: Lyra.Supervisor]
    Supervisor.start_link(children(), opts)
  end

  defp children do
    [
      # Starts a worker by calling: Lyra.Worker.start_link(arg1, arg2, arg3)
      # worker(Lyra.Worker, [arg1, arg2, arg3]),
    ]
  end
end
