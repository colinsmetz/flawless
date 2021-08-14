defmodule Validator.Helpers do
  alias Validator.{ListSpec, ValueSpec, TupleSpec}

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

  def value(opts \\ []) do
    %ValueSpec{
      required: opts |> Keyword.get(:required, false),
      checks: opts |> Keyword.get(:checks, []),
      schema: opts |> Keyword.get(:schema, nil),
      type: opts |> Keyword.get(:type, :any),
      cast_from: opts |> Keyword.get(:cast_from, [])
    }
  end

  def list(item_type, opts \\ []) do
    %ListSpec{
      required: opts |> Keyword.get(:required, false),
      checks: opts |> Keyword.get(:checks, []),
      item_type: item_type,
      cast_from: opts |> Keyword.get(:cast_from, [])
    }
  end

  def tuple(elem_types, opts \\ []) do
    %TupleSpec{
      required: opts |> Keyword.get(:required, false),
      checks: opts |> Keyword.get(:checks, []),
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

  def integer(opts \\ []), do: value_with_type(:integer, Validator.Rule.is_integer_type(), opts)
  def req_integer(opts \\ []), do: required(&integer/1, opts)

  def string(opts \\ []), do: value_with_type(:string, Validator.Rule.is_string_type(), opts)
  def req_string(opts \\ []), do: required(&string/1, opts)

  def float(opts \\ []), do: value_with_type(:float, Validator.Rule.is_float_type(), opts)
  def req_float(opts \\ []), do: required(&float/1, opts)

  def number(opts \\ []), do: value_with_type(:number, Validator.Rule.is_number_type(), opts)
  def req_number(opts \\ []), do: required(&number/1, opts)

  def boolean(opts \\ []), do: value_with_type(:boolean, Validator.Rule.is_boolean_type(), opts)
  def req_boolean(opts \\ []), do: required(&boolean/1, opts)

  def atom(opts \\ []), do: value_with_type(:atom, Validator.Rule.is_atom_type(), opts)
  def req_atom(opts \\ []), do: required(&atom/1, opts)
end
