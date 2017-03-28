use Mix.Config

config :lyra, :digest,
  size: 160

config :lyra,
  ring: Lyra.Ring.ErlangProcess

# import_config "#{Mix.env}.exs"
