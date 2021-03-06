defmodule EctoFallback.Mixfile do
  use Mix.Project

  def project do
    [
      app: :ecto_fallback,
      version: "0.1.0",
      elixir: "~> 1.5",
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      applications: [:logger, :ecto, :postgrex],
      mod: {EctoFallback.Application, []}
    ]
  end

  defp deps do
    [
      {:nebulex, "~> 1.0"},
      {:ecto, "~> 2.0"},
      {:postgrex, "~> 0.11"}
    ]
  end
end
