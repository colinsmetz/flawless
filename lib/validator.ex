defmodule Validator do
  defmodule ValueSpec do
    defstruct required: false, checks: [], schema: nil
  end

  defmodule ListSpec do
    defstruct required: false, checks: [], item_type: nil
  end

  def validate(value, schema, context \\ []) do
    case schema do
      %ListSpec{} -> validate_list(value, schema, context)
      [item_type] -> validate_list(value, list(item_type), context)
      %ValueSpec{} -> validate_value(value, schema, context)
      %{} -> validate_map(value, schema, context)
    end
  end

  def validate_map(map, %{} = schema, context \\ []) do
    field_errors =
      schema
      |> Enum.map(fn {field_name, field} ->
        cond do
          is_nil(map[field_name]) ->
            []

          true ->
            validate(map[field_name], field, context ++ [field_name])
        end
      end)

    [
      unexpected_fields_error(map, schema, context),
      missing_fields_error(map, schema, context),
      field_errors
    ]
    |> List.flatten()
  end

  defp validate_value(value, spec, context) do
    top_level_errors =
      spec.checks
      |> Enum.map(fn check ->
        check.(value, context)
      end)

    sub_errors =
      cond do
        not is_nil(spec.schema) -> validate_map(value, spec.schema, context)
        true -> []
      end

    [
      top_level_errors,
      sub_errors
    ]
    |> List.flatten()
  end

  defp validate_list(list, spec, context) when is_list(list) do
    top_level_errors =
      spec.checks
      |> Enum.map(fn check ->
        check.(list, context)
      end)

    items_errors =
      list
      |> Enum.with_index()
      |> Enum.map(fn {value, index} ->
        validate(value, spec.item_type, context ++ [index])
      end)
      |> List.flatten()

    [
      top_level_errors,
      items_errors
    ]
    |> List.flatten()
  end

  defp validate_list(list, _field, _context) do
    ["Expected a list, got: #{inspect(list)}"]
  end

  defp unexpected_fields_error(map, schema, context) do
    map_fields = map |> Map.keys()
    schema_fields = schema |> Map.keys()

    unexpected_fields = map_fields -- schema_fields

    if unexpected_fields == [] do
      []
    else
      [Validator.Error.new("Unexpected fields: #{inspect(unexpected_fields)}", context)]
    end
  end

  defp missing_fields_error(map, schema, context) do
    missing_fields =
      for {field_name, field} <- schema,
          is_nil(map[field_name]) and field |> Map.get(:required, false) do
        field_name
      end

    if missing_fields == [] do
      []
    else
      [Validator.Error.new("Missing required fields: #{inspect(missing_fields)}", context)]
    end
  end

  defp required(value_fun, opts) do
    opts |> Keyword.put(:required, true) |> value_fun.()
  end

  defp value_with_rule(rule, opts) do
    checks = opts |> Keyword.get(:checks, [])
    updated_checks = [rule | checks]
    opts |> Keyword.put(:checks, updated_checks) |> value()
  end

  def value(opts \\ []) do
    %ValueSpec{
      required: opts |> Keyword.get(:required, false),
      checks: opts |> Keyword.get(:checks, []),
      schema: opts |> Keyword.get(:schema, nil)
    }
  end

  def list(item_type, opts \\ []) do
    %ListSpec{
      required: opts |> Keyword.get(:required, false),
      checks: opts |> Keyword.get(:checks, []),
      item_type: item_type
    }
  end

  def map(schema, opts \\ []) do
    opts |> Keyword.put(:schema, schema) |> value()
  end

  def req_value(opts \\ []), do: required(&value/1, opts)
  def req_list(opts \\ []), do: required(&list/1, opts)
  def req_map(schema, opts \\ []), do: required(&map(schema, &1), opts)

  def integer(opts \\ []), do: value_with_rule(Validator.Rule.is_integer_type(), opts)
  def req_integer(opts \\ []), do: required(&integer/1, opts)

  def string(opts \\ []), do: value_with_rule(Validator.Rule.is_string_type(), opts)
  def req_string(opts \\ []), do: required(&string/1, opts)

  def float(opts \\ []), do: value_with_rule(Validator.Rule.is_float_type(), opts)
  def req_float(opts \\ []), do: required(&float/1, opts)

  def number(opts \\ []), do: value_with_rule(Validator.Rule.is_number_type(), opts)
  def req_number(opts \\ []), do: required(&number/1, opts)

  def boolean(opts \\ []), do: value_with_rule(Validator.Rule.is_boolean_type(), opts)
  def req_boolean(opts \\ []), do: required(&boolean/1, opts)
end
