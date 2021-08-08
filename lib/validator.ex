defmodule Validator do
  @moduledoc """
  Validator is a library meant for validating JSON-like data structures, i.e. ones
  that contain maps, arrays or single values. The validation is done by providing
  the `validate` function with a value and a schema.

  Schemas can be defined with the helper of the `defvalidator` macro, whose main
  purpose is to import helpers locally.
  """

  alias Validator.Error

  @type spec_type() :: Validator.ValueSpec.t() | Validator.ListSpec.t() | map()

  defmodule ValueSpec do
    @moduledoc """
    Represents a simple value or a map.

    The `schema` field is used when the value is a map, and is `nil` otherwise.
    """
    defstruct required: false, checks: [], schema: nil

    @type t() :: %__MODULE__{
      required: boolean(),
      checks: list(Validator.Rule.t()),
      schema: map() | nil
    }
  end

  defmodule ListSpec do
    @moduledoc """
    Represents a list of elements.

    Each element must conform to the `item_type` definition.
    """
    defstruct required: false, checks: [], item_type: nil

    @type t() :: %__MODULE__{
      required: boolean(),
      checks: list(Validator.Rule.t()),
      item_type: Validator.spec_type()
    }
  end

  defmacro defvalidator(do: body) do
    quote do
      import Validator
      import Validator.Rule
      import Validator.Helpers

      unquote(body)
    end
  end

  @spec validate(any, spec_type(), list) :: list(Error.t())
  def validate(value, schema, context \\ []) do
    case schema do
      %ListSpec{} -> validate_list(value, schema, context)
      [item_type] -> validate_list(value, Validator.Helpers.list(item_type), context)
      %ValueSpec{} -> validate_value(value, schema, context)
      %{} -> validate_map(value, schema, context)
    end
  end

  defp validate_map(map, %{} = schema, context) when is_map(map) do
    field_errors =
      schema
      |> Enum.map(fn {field_name, field} ->
        case Map.fetch(map, field_name) do
          :error -> []
          {:ok, value} -> validate(value, field, context ++ [field_name])
        end
      end)

    [
      unexpected_fields_error(map, schema, context),
      missing_fields_error(map, schema, context),
      field_errors
    ]
    |> List.flatten()
  end

  defp validate_map(map, _spec, context) do
    [Error.new("Expected a map, got: #{inspect(map)}", context)]
  end

  defp validate_value(value, spec, context) do
    top_level_errors =
      spec.checks
      |> Enum.map(fn check -> check.(value, context) end)

    sub_errors =
      case spec.schema do
        nil -> []
        schema -> validate_map(value, schema, context)
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
      |> Enum.map(fn check -> check.(list, context) end)

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

  defp validate_list(list, _spec, context) do
    [Error.new("Expected a list, got: #{inspect(list)}", context)]
  end

  defp unexpected_fields_error(map, schema, context) do
    map_fields = map |> Map.keys()
    schema_fields = schema |> Map.keys()

    unexpected_fields = map_fields -- schema_fields

    if unexpected_fields == [] do
      []
    else
      [Error.new("Unexpected fields: #{inspect(unexpected_fields)}", context)]
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
      [Error.new("Missing required fields: #{inspect(missing_fields)}", context)]
    end
  end
end
