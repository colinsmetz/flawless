
defimpl Inspect, for: Validator.Spec do
  import Inspect.Algebra
  alias Validator.Spec

  def inspect(
        %Spec{
          type: type,
          cast_from: cast_from,
          nil: nillable,
          checks: checks,
          late_checks: late_checks,
          for: subspec
        },
        opts
      ) do
    specific_params = subspec_params(subspec, opts)

    params =
      specific_params
      |> Enum.concat([
        nillable(nillable, opts),
        checks(checks, opts),
        late_checks(late_checks, opts),
        cast_from(cast_from, opts)
      ])
      |> Enum.reject(&(&1 == nil))

    concat([
      if(match?(%Spec.Literal{}, subspec), do: "literal", else: "#{type}"),
      function_args(params, opts)
    ])
  end

  defp subspec_params(%Spec.Value{schema: schema}, opts) do
    [if(schema, do: [to_doc(schema, opts)], else: nil)]
  end

  defp subspec_params(%Spec.Literal{value: value}, opts) do
    [[to_doc(value, opts)]]
  end

  defp subspec_params(%Spec.List{item_type: item_type}, opts) do
    [[to_doc(item_type, opts)]]
  end

  defp subspec_params(%Spec.Tuple{elem_types: elem_types}, opts) do
    [[to_doc(elem_types, opts)]]
  end

  defp subspec_params(%Spec.Struct{schema: schema, module: _module}, opts) do
    [[to_doc(schema, opts)]]
  end

  defp function_args(args, opts) do
    container_doc("(", args, ")", opts, fn i, _ -> concat(i) end, separator: ",")
  end

  defp checks([], _opts), do: nil
  defp checks(checks, opts), do: ["checks: #", to_doc(length(checks), opts)]

  defp late_checks([], _opts), do: nil
  defp late_checks(late_checks, opts), do: ["late_checks: #", to_doc(length(late_checks), opts)]

  defp cast_from([], _opts), do: nil
  defp cast_from(cast_from, opts), do: ["cast_from: ", to_doc(cast_from, opts)]

  defp nillable(:default, _opts), do: nil
  defp nillable(nillable, opts), do: ["nil: ", to_doc(nillable, opts)]
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
