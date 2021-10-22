defmodule Flawless.MixProject do
  use Mix.Project

  def project do
    [
      app: :flawless,
      version: "0.1.0",
      elixir: "~> 1.11",
      start_permanent: Mix.env() == :prod,
      deps: deps(),

      # Docs
      name: "Flawless",
      docs: [
        # The main page in the docs
        main: "readme",
        api_reference: false,
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
      {:ex_doc, "~> 0.25", only: :dev, runtime: false}
    ]
  end

  defp extras do
    [
      "README.md",
      "guides/schema_definition.md",
      "guides/custom_checks.md"
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
        Flawless.Utils.Enum
      ]
    ]
  end
end
