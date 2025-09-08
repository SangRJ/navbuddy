defmodule NavBuddy.MixProject do
  use Mix.Project

  @version "0.2.5"
  @source_url "https://github.com/SangRJ/navbuddy"

  def project do
    [
      app: :navbuddy,
      version: @version,
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: description(),
      package: package(),
      docs: docs(),
      name: "NavBuddy",
      source_url: @source_url
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:phoenix, ">= 1.7.0"},
      {:phoenix_live_view, ">= 0.20.0"},
      {:phoenix_html, ">= 4.0.0"},
      {:jason, ">= 1.0.0"},

      # Dev/test dependencies
      {:ex_doc, "~> 0.29", only: :dev, runtime: false},
      {:credo, "~> 1.6", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.0", only: [:dev], runtime: false}
    ]
  end

  defp description do
    "Advanced configurable navigation component for Phoenix LiveView applications with permissions-based filtering, comprehensive validation, convenient helper functions, and support for dropdowns, mega menus, and mobile-responsive design."
  end

  defp package do
    [
      name: "navbuddy",
      files: ~w(lib priv .formatter.exs mix.exs README* LICENSE*),
      licenses: ["MIT"],
      links: %{
        "GitHub" => @source_url,
        "Docs" => "https://hexdocs.pm/navbuddy"
      },
      maintainers: ["Rogers Sangale"]
    ]
  end

  defp docs do
    [
      main: "NavBuddy",
      source_ref: "v#{@version}",
      source_url: @source_url,
      extras: ["README.md", "INTEGRATION_EXAMPLE.md", "LICENSE"]
    ]
  end
end
