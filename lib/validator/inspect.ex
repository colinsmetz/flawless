defmodule Validator.Inspect do
  import Inspect.Algebra

  def function_args(args, opts) do
    container_doc("(", args, ")", opts, fn i, _ -> concat(i) end, separator: ",")
  end

  def checks([], _opts), do: nil
  def checks(checks, opts), do: ["checks: #", to_doc(length(checks), opts)]

  def cast_from([], _opts), do: nil
  def cast_from(cast_from, opts), do: ["cast_from: ", to_doc(cast_from, opts)]
end

defimpl Inspect, for: Validator.Spec do
  import Inspect.Algebra
  import Validator.Inspect
  alias Validator.Spec

  def inspect(
        %Spec{
          type: type,
          cast_from: cast_from,
          checks: checks,
          for: %Spec.Value{schema: schema}
        },
        opts
      ) do
    params =
      [
        if(schema, do: [to_doc(schema, opts)], else: nil),
        checks(checks, opts),
        cast_from(cast_from, opts)
      ]
      |> Enum.reject(&(&1 == nil))

    concat([
      "#{type}",
      function_args(params, opts)
    ])
  end

  def inspect(%Spec{for: %Spec.Literal{value: value}, cast_from: cast_from}, opts) do
    params =
      [
        [to_doc(value, opts)],
        cast_from(cast_from, opts)
      ]
      |> Enum.reject(&(&1 == nil))

    concat(["literal", function_args(params, opts)])
  end

  def inspect(
        %Spec{for: %Spec.List{item_type: item_type}, cast_from: cast_from, checks: checks},
        opts
      ) do
    params =
      [
        [to_doc(item_type, opts)],
        checks(checks, opts),
        cast_from(cast_from, opts)
      ]
      |> Enum.reject(&(&1 == nil))

    concat([
      "list",
      function_args(params, opts)
    ])
  end

  def inspect(
        %Spec{
          for: %Spec.Tuple{elem_types: elem_types},
          cast_from: cast_from,
          checks: checks
        },
        opts
      ) do
    params =
      [
        [to_doc(elem_types, opts)],
        checks(checks, opts),
        cast_from(cast_from, opts)
      ]
      |> Enum.reject(&(&1 == nil))

    concat([
      "tuple",
      function_args(params, opts)
    ])
  end

  def inspect(
        %Spec{
          type: type,
          cast_from: cast_from,
          checks: checks,
          for: %Spec.Struct{schema: schema, module: _module}
        },
        opts
      ) do
    params =
      [
        [to_doc(schema, opts)],
        checks(checks, opts),
        cast_from(cast_from, opts)
      ]
      |> Enum.reject(&(&1 == nil))

    concat([
      "#{type}",
      function_args(params, opts)
    ])
  end
end

defimpl Inspect, for: Validator.AnyOtherKey do
  alias Validator.AnyOtherKey

  def inspect(%AnyOtherKey{}, _opts) do
    "any_key()"
  end
end

defimpl Inspect, for: Validator.OptionalKey do
  alias Validator.OptionalKey

  def inspect(%OptionalKey{key: key}, _opts) do
    "maybe(#{inspect(key)})"
  end
end
