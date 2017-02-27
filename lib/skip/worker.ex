defmodule Skip.Worker do
  use GenServer

  defstruct [:successor]

  def resolve(worker, name) do
    ## Digest in the client
    GenServer.call(worker, {:resolve, digest(name)})
  end

  ## Generic Server Machinery Interface

  def init do
    {:ok,
     %__MODULE__{successor: self()}
    }
  end

  def handle_call({:resolve, x}, _, s) do
    if successor?(x, point(self()), point(s.successor)) do
      success(self(), s)
    else
      failure(s)
    end
  end

  ## Ancillary

  defp successor?(x, u, v) do
    Skip.Modular.epsilon?(x, include: u, exclude: v)
  end

  defp point(x) when is_pid(x) do
    x
    |> identifier()
    |> digest()
  end

  defp digest(x) when is_list(x) or is_binary(x) do
    :crypto.bytes_to_integer(:crypto.hash(:sha, x))
  end

  defp identifier(x) when is_pid(x) do
    :erlang.pid_to_list(x)
  end

  defp success(value, state) do
    {:reply, value, state}
  end

  defp failure(state) do
    {:reply, :failure, state}
  end
end
