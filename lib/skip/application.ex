defmodule Skip.Application do
  @moduledoc false

  use Application

  def start(_, _) do
    import Supervisor.Spec, warn: false

    opts = [strategy: :one_for_one, name: Skip.Supervisor]
    Supervisor.start_link(children(), opts)
  end

  defp children do
    [
      # Starts a worker by calling: Skip.Worker.start_link(arg1, arg2, arg3)
      # worker(Skip.Worker, [arg1, arg2, arg3]),
    ]
  end
end
