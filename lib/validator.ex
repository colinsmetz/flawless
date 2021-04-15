defmodule Validator do
  defmodule Field do
    defstruct required: false, checks: [], schema: nil
  end

  defmodule FieldList do
    defstruct required: false, checks: [], schema: nil
  end

  def validate(map, %{} = schema, context \\ []) do
    field_errors =
      schema
      |> Enum.map(fn {field_name, field} ->
        cond do
          is_nil(map[field_name]) ->
            []

          match?(%FieldList{}, field) ->
            validate_list(map[field_name], field_name, field, context ++ [field_name])

          match?(%Field{}, field) ->
            validate_field(map[field_name], field_name, field, context ++ [field_name])
        end
      end)

    [
      unexpected_fields_error(map, schema, context),
      missing_fields_error(map, schema, context),
      field_errors
    ]
    |> List.flatten()
  end

  defp validate_field(value, field_name, field, context) do
    top_level_errors =
      field.checks
      |> Enum.map(fn check ->
        check.(field_name, value)
      end)

    sub_errors =
      if not is_nil(field.schema) do
        validate(value, field.schema, context)
      else
        []
      end

    [
      top_level_errors,
      sub_errors
    ]
    |> List.flatten()
  end

  defp validate_list(list, field_name, field, context) when is_list(list) do
    list
    |> Enum.with_index()
    |> Enum.map(fn {value, index} ->
      validate_field(value, field_name, field, context ++ [index])
    end)
    |> List.flatten()
  end

  defp validate_list(list, _field_name, _field, context) do
    ["Expected a list in #{show_context(context)}, got: #{inspect(list)}"]
  end

  defp unexpected_fields_error(map, schema, context) do
    map_fields = map |> Map.keys()
    schema_fields = schema |> Map.keys()

    unexpected_fields = map_fields -- schema_fields

    if unexpected_fields == [] do
      []
    else
      ["Unexpected fields found in #{show_context(context)}: #{inspect(unexpected_fields)}"]
    end
  end

  defp missing_fields_error(map, schema, context) do
    missing_fields =
      for {field_name, field} <- schema,
          is_nil(map[field_name]) and field.required do
        field_name
      end

    if missing_fields == [] do
      []
    else
      ["Missing required fields in #{show_context(context)}: #{inspect(missing_fields)}"]
    end
  end

  defp show_context(context) do
    context
    |> Enum.join("/")
  end

  defp required(field_fun, opts) do
    opts |> Keyword.put(:required, true) |> field_fun.()
  end

  defp field_with_rule(rule, opts) do
    checks = opts |> Keyword.get(:checks, [])
    updated_checks = [rule | checks]
    opts |> Keyword.put(:checks, updated_checks) |> field()
  end

  def field(opts \\ []) do
    %Field{
      required: opts |> Keyword.get(:required, false),
      checks: opts |> Keyword.get(:checks, []),
      schema: opts |> Keyword.get(:schema, nil)
    }
  end

  def list(opts \\ []) do
    %FieldList{
      required: opts |> Keyword.get(:required, false),
      checks: opts |> Keyword.get(:checks, []),
      schema: opts |> Keyword.get(:schema, nil)
    }
  end

  def map(schema, opts \\ []) do
    opts |> Keyword.put(:schema, schema) |> field()
  end

  def req_field(opts \\ []), do: required(&field/1, opts)
  def req_list(opts \\ []), do: required(&list/1, opts)
  def req_map(schema, opts \\ []), do: required(&map(schema, &1), opts)

  def integer(opts \\ []), do: field_with_rule(Validator.Rule.is_integer_type(), opts)
  def req_integer(opts \\ []), do: required(&integer/1, opts)

  def string(opts \\ []), do: field_with_rule(Validator.Rule.is_string_type(), opts)
  def req_string(opts \\ []), do: required(&string/1, opts)

  def float(opts \\ []), do: field_with_rule(Validator.Rule.is_float_type(), opts)
  def req_float(opts \\ []), do: required(&float/1, opts)

  def number(opts \\ []), do: field_with_rule(Validator.Rule.is_number_type(), opts)
  def req_number(opts \\ []), do: required(&number/1, opts)

  def boolean(opts \\ []), do: field_with_rule(Validator.Rule.is_boolean_type(), opts)
  def req_boolean(opts \\ []), do: required(&boolean/1, opts)
end
