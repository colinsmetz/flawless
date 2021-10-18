defmodule Validator.MixProject do
  use Mix.Project

  def project do
    [
      app: :validator,
      version: "0.1.0",
      elixir: "~> 1.11",
      start_permanent: Mix.env() == :prod,
      deps: deps(),

      # Docs
      name: "Validator",
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
        Validator.Types.Date,
        Validator.Types.DateTime,
        Validator.Types.NaiveDateTime,
        Validator.Types.Time
      ],
      "Spec elements": [
        Validator.AnyOtherKey,
        Validator.OptionalKey,
        Validator.Spec,
        Validator.Spec.List,
        Validator.Spec.Literal,
        Validator.Spec.Struct,
        Validator.Spec.Tuple,
        Validator.Spec.Value
      ],
      "Validation helpers": [
        Validator.Context,
        Validator.Utils.Enum
      ]
    ]
  end
end
