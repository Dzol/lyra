defmodule Lyra do
  @moduledoc """
  A Chord in Elixir
  """

  @type handle :: pid | ip4 | nil
  @type ip4    :: [byte]

  import GenServer, only: [call: 2]

  ## Interface for Client

  @doc """
  Prompt Lyra for changes
  """
  @spec prompt(local :: handle) :: :ok
  def prompt(vertex) when is_pid(vertex) do
    call(vertex, :prompt)
  end

  @doc """
  Query Lyra
  """
  @spec query(local :: handle, iodata) :: remote :: handle
  def query(vertex, symbol) when is_pid(vertex) and is_list(symbol) or is_binary(symbol) do
    alias Lyra.Worker

    call(vertex, {:successor, Worker.digest(symbol)})
  end
end
