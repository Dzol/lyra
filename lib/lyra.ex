defmodule Lyra do
  @moduledoc """
  A Chord in Elixir.
  """

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
    Lyra.Worker.query(vertex, name)
  end
end
