defmodule Lyra do
  @moduledoc """
  A Chord in Elixir.
  """

  import GenServer, only: [call: 2]

  @doc """
  Prompt Lyra for changes on the Ring.
  """
  def prompt(x) do
    call(x, :prompt)
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
