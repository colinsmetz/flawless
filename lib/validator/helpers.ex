defmodule Validator.Helpers do
  @moduledoc """

  A series of helper functions to build schemas.

  ## Common options

  * `checks`: a list of checks.
  * `check`: a single check. Can be repeated.
  * `late_checks`: a list of checks to evaluate only if all other checks passed on that element.
  * `late_check`: a single late check. Can be repeated.
  * `nil`: whether the value is nillable.
  * `cast_from`: the types from which it is allowed to cast the value to the expected type.

  """
  alias Validator.Rule
  alias Validator.Types
  alias Validator.Spec
  alias Validator.{AnyOtherKey, OptionalKey}

  defp value_with_type(type, opts) do
    opts
    |> Keyword.put(:type, type)
    |> value()
  end

  defp extract_checks(opts, type) do
    opts
    |> Keyword.get(:checks, [])
    |> Enum.concat(Keyword.get_values(opts, :check))
    |> Enum.concat(built_in_checks(opts, type))
  end

  defp extract_late_checks(opts) do
    opts
    |> Keyword.get(:late_checks, [])
    |> Enum.concat(Keyword.get_values(opts, :late_check))
  end

  defp build_spec(subspec, type, opts) do
    %Spec{
      checks: extract_checks(opts, type),
      late_checks: extract_late_checks(opts),
      type: type,
      cast_from: opts |> Keyword.get(:cast_from, []),
      nil: opts |> Keyword.get(nil, :default),
      for: subspec
    }
  end

  def value(opts \\ []) do
    type = opts |> Keyword.get(:type, :any)

    %Spec.Value{schema: opts |> Keyword.get(:schema, nil)}
    |> build_spec(type, opts)
  end

  def list(item_type, opts \\ []) do
    %Spec.List{item_type: item_type}
    |> build_spec(:list, opts)
  end

  def tuple(elem_types, opts \\ []) do
    %Spec.Tuple{elem_types: elem_types}
    |> build_spec(:tuple, opts)
  end

  def map(schema, opts \\ []) do
    opts
    |> Keyword.put(:schema, schema)
    |> Keyword.put(:type, :map)
    |> value()
  end

  def structure(schema_or_module, opts \\ [])

  def structure(%module{} = schema, opts) do
    %Spec.Struct{module: module, schema: schema}
    |> build_spec(:struct, opts)
  end

  def structure(module, opts) when is_atom(module) do
    %Spec.Struct{module: module, schema: nil}
    |> build_spec(:struct, opts)
  end

  def literal(value, opts \\ []) do
    type = Types.type_of(value)

    %Spec.Literal{value: value}
    |> build_spec(type, opts)
  end

  def integer(opts \\ []), do: value_with_type(:integer, opts)
  def string(opts \\ []), do: value_with_type(:string, opts)
  def float(opts \\ []), do: value_with_type(:float, opts)
  def number(opts \\ []), do: value_with_type(:number, opts)
  def boolean(opts \\ []), do: value_with_type(:boolean, opts)
  def atom(opts \\ []), do: value_with_type(:atom, opts)
  def pid(opts \\ []), do: value_with_type(:pid, opts)
  def ref(opts \\ []), do: value_with_type(:ref, opts)
  def function(opts \\ []), do: value_with_type(:function, opts)
  def port(opts \\ []), do: value_with_type(:port, opts)

  def any_key(), do: %AnyOtherKey{}
  def maybe(key), do: %OptionalKey{key: key}

  def opaque_struct_type(module, user_opts, opts \\ []) do
    converter = Keyword.get(opts, :converter, nil)
    shortcut_rules = Keyword.get(opts, :shortcut_rules, [])
    checks = built_in_checks(user_opts, shortcut_rules) ++ Keyword.get(user_opts, :checks, [])

    cast_from =
      user_opts
      |> Keyword.get(:cast_from, [])
      |> List.wrap()
      |> Enum.map(fn
        type when is_nil(converter) -> type
        {_, with: _converter} = type -> type
        type -> {type, with: &converter.(&1, type)}
      end)

    structure(module, Keyword.merge(user_opts, checks: checks, cast_from: cast_from))
  end

  #######################
  #   BUILT-IN CHECKS   #
  #######################

  defp built_in_checks(opts, rules) when is_list(rules) do
    rules
    |> Enum.reduce([], fn {key, rule}, acc ->
      case Keyword.fetch(opts, key) do
        {:ok, args} ->
          rule
          |> Function.info()
          |> Keyword.get(:arity, 1)
          |> case do
            0 when args == true -> [rule.() | acc]
            0 -> acc
            1 -> [rule.(args) | acc]
            _ -> [apply(rule, args) | acc]
          end

        :error ->
          acc
      end
    end)
    |> Enum.reverse()
  end

  defp built_in_checks(opts, :number) do
    opts
    |> built_in_checks(
      min: &Rule.min/1,
      max: &Rule.max/1,
      in: &Rule.one_of/1,
      between: &Rule.between/2
    )
  end

  defp built_in_checks(opts, :integer) do
    built_in_checks(opts, :number)
  end

  defp built_in_checks(opts, :float) do
    built_in_checks(opts, :number)
  end

  defp built_in_checks(opts, :string) do
    opts
    |> built_in_checks(
      min_length: &Rule.min_length/1,
      max_length: &Rule.max_length/1,
      length: &Rule.exact_length/1,
      in: &Rule.one_of/1,
      non_empty: &Rule.non_empty/0,
      format: &Rule.match/1
    )
  end

  defp built_in_checks(opts, :list) do
    opts
    |> built_in_checks(
      min_length: &Rule.min_length/1,
      max_length: &Rule.max_length/1,
      length: &Rule.exact_length/1,
      in: &Rule.one_of/1,
      non_empty: &Rule.non_empty/0,
      no_duplicate: &Rule.no_duplicate/0
    )
  end

  defp built_in_checks(opts, :function) do
    opts
    |> built_in_checks(
      in: &Rule.one_of/1,
      arity: &Rule.arity/1
    )
  end

  defp built_in_checks(opts, _) do
    opts
    |> built_in_checks(in: &Rule.one_of/1)
  end
end
