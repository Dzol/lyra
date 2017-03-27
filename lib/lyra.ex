defmodule Lyra do
  @moduledoc """
  A Chord in Elixir.
  """

  import GenServer, only: [call: 2]

  @doc """
  Prompt Lyra for changes.
  """
  def prompt(vertex) do
    Lyra.Worker.prompt(vertex)
  end

  @doc """
  Query Lyra for a vertex.
  """
  def query(vertex, name) when is_pid(vertex) and is_list(name) or is_binary(name) do
    Lyra.Worker.resolve(vertex, name)
  end

  @doc """
  Enter a ring.
  """
  def enter do
    :ok
  end

  @doc """
  Exit the ring.
  """
  def exit do
    :ok
  end
end
