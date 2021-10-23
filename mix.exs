defmodule Flawless.MixProject do
  use Mix.Project

  @version "0.1.0"
  @repo_url "https://github.com/colinsmetz/flawless"

  def project do
    [
      app: :flawless,
      description: "Validate any data in Elixir.",
      version: @version,
      elixir: "~> 1.11",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      package: package(),
      source_url: @repo_url,

      # Docs
      name: "Flawless",
      docs: [
        # The main page in the docs
        main: "readme",
        api_reference: false,
        logo: "logo.png",
        extras: extras(),
        groups_for_modules: groups_for_modules()
      ]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:dialyxir, "~> 1.0", only: [:dev], runtime: false},
      {:ex_doc, "~> 0.25", only: :dev, runtime: false},
      {:benchee, "~> 1.0", only: :dev},
      {:skooma, "~> 0.2.0", only: :dev},
      {:norm, "~> 0.13.0", only: :dev}
    ]
  end

  defp extras do
    [
      "README.md",
      "guides/schema_definition.md",
      "guides/custom_checks.md",
      "guides/optimization.md"
    ]
  end

  defp groups_for_modules do
    [
      "Opaque structs": [
        Flawless.Types.Date,
        Flawless.Types.DateTime,
        Flawless.Types.NaiveDateTime,
        Flawless.Types.Time
      ],
      "Spec elements": [
        Flawless.AnyOtherKey,
        Flawless.OptionalKey,
        Flawless.Spec,
        Flawless.Spec.List,
        Flawless.Spec.Literal,
        Flawless.Spec.Struct,
        Flawless.Spec.Tuple,
        Flawless.Spec.Value
      ],
      "Validation helpers": [
        Flawless.Context,
        Flawless.Utils.Enum,
        Flawless.Utils.Interpolation
      ]
    ]
  end

  defp package() do
    [
      files: ~w(lib .formatter.exs mix.exs README.md LICENSE),
      licenses: ["MIT"],
      links: %{"GitHub" => @repo_url}
    ]
  end
end
