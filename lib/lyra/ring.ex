defmodule Lyra.Ring do
  @moduledoc """
  Interface for the Ring

  This is how a vertices communicate: both inbound + outbound.
  """

  @callback precede(term, term) :: :ok
  @callback succeed(term, term) :: :ok

  @callback predecessor(vertex :: term, value :: term) :: {:ok, vertex :: term}
  @callback successor(vertex :: term) :: {:ok, vertex :: term}
end
