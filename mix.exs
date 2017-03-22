defmodule Lyra.Mixfile do
  use Mix.Project

  def project do
    [app: :lyra,
     version: "0.1.0",
     elixir: "~> 1.4",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps(),
     aliases: aliases(),
     test_pattern: "*_{test,property}.exs",
     docs: documentation()] ++ cover()
  end

  def application do
    [extra_applications: [:logger],
     mod: {Lyra.Application, []}]
  end

  defp deps do
    [{:credo, "~> 0.5", only: [:dev, :test]},
     {:dialyxir, "~> 0.4", only: [:dev], runtime: false},
     {:excoveralls, "~> 0.6", only: :test},
     {:eqc_ex, "~> 1.4", only: :test},
     {:ex_doc, "~> 0.15", only: :dev, runtime: false}]
  end

  defp aliases do
    [property: [&test/1, "test property/"]]
  end

  defp documentation do
    [output: "docs"]
  end

  defp cover do
    [test_coverage: [tool: ExCoveralls],
     preferred_cli_env: [coveralls: :test]]
  end

  defp test(_) do
    Mix.env(:test)
  end
end
