defmodule Validator.Helpers do
  alias Validator.{ListSpec, ValueSpec, TupleSpec}
  alias Validator.Rule

  defp required(value_fun, opts) do
    opts |> Keyword.put(:required, true) |> value_fun.()
  end

  defp value_with_type(type, type_rule, opts) do
    checks = opts |> Keyword.get(:checks, [])
    updated_checks = [type_rule | checks]

    opts
    |> Keyword.put(:type, type)
    |> Keyword.put(:checks, updated_checks)
    |> value()
  end

  defp extract_checks(opts, type) do
    opts
    |> Keyword.get(:checks, [])
    |> Enum.concat(Keyword.get_values(opts, :check))
    |> Enum.concat(built_in_checks(opts, type))
  end

  def value(opts \\ []) do
    type = opts |> Keyword.get(:type, :any)

    %ValueSpec{
      required: opts |> Keyword.get(:required, false),
      checks: extract_checks(opts, type),
      schema: opts |> Keyword.get(:schema, nil),
      type: type,
      cast_from: opts |> Keyword.get(:cast_from, [])
    }
  end

  def list(item_type, opts \\ []) do
    %ListSpec{
      required: opts |> Keyword.get(:required, false),
      checks: extract_checks(opts, :list),
      item_type: item_type,
      cast_from: opts |> Keyword.get(:cast_from, [])
    }
  end

  def tuple(elem_types, opts \\ []) do
    %TupleSpec{
      required: opts |> Keyword.get(:required, false),
      checks: extract_checks(opts, :tuple),
      elem_types: elem_types,
      cast_from: opts |> Keyword.get(:cast_from, [])
    }
  end

  def map(schema, opts \\ []) do
    opts
    |> Keyword.put(:schema, schema)
    |> Keyword.put(:type, :map)
    |> value()
  end

  def req_value(opts \\ []), do: required(&value/1, opts)
  def req_list(item_type, opts \\ []), do: required(&list(item_type, &1), opts)
  def req_map(schema, opts \\ []), do: required(&map(schema, &1), opts)
  def req_tuple(elem_types, opts \\ []), do: required(&tuple(elem_types, &1), opts)

  def integer(opts \\ []), do: value_with_type(:integer, Rule.is_integer_type(), opts)
  def req_integer(opts \\ []), do: required(&integer/1, opts)

  def string(opts \\ []), do: value_with_type(:string, Rule.is_string_type(), opts)
  def req_string(opts \\ []), do: required(&string/1, opts)

  def float(opts \\ []), do: value_with_type(:float, Rule.is_float_type(), opts)
  def req_float(opts \\ []), do: required(&float/1, opts)

  def number(opts \\ []), do: value_with_type(:number, Rule.is_number_type(), opts)
  def req_number(opts \\ []), do: required(&number/1, opts)

  def boolean(opts \\ []), do: value_with_type(:boolean, Rule.is_boolean_type(), opts)
  def req_boolean(opts \\ []), do: required(&boolean/1, opts)

  def atom(opts \\ []), do: value_with_type(:atom, Rule.is_atom_type(), opts)
  def req_atom(opts \\ []), do: required(&atom/1, opts)

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

  defp built_in_checks(opts, _) do
    opts
    |> built_in_checks(in: &Rule.one_of/1)
  end
end
