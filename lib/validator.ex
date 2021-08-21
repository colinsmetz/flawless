defmodule Validator do
  @moduledoc """
  Validator is a library meant for validating JSON-like data structures, i.e. ones
  that contain maps, arrays or single values. The validation is done by providing
  the `validate` function with a value and a schema.

  Schemas can be defined with the helper of the `defvalidator` macro, whose main
  purpose is to import helpers locally.
  """

  alias Validator.Error
  alias Validator.Helpers
  alias Validator.Types

  @type spec_type() ::
          Validator.ValueSpec.t()
          | Validator.ListSpec.t()
          | Validator.TupleSpec.t()
          | map()
          | list()

  defmodule ValueSpec do
    @moduledoc """
    Represents a simple value or a map.

    The `schema` field is used when the value is a map, and is `nil` otherwise.
    """
    defstruct required: false, checks: [], schema: nil, type: :any, cast_from: []

    @type t() :: %__MODULE__{
            required: boolean(),
            checks: list(Validator.Rule.t()),
            schema: map() | nil,
            type: atom(),
            cast_from: list(atom()) | atom()
          }
  end

  defmodule ListSpec do
    @moduledoc """
    Represents a list of elements.

    Each element must conform to the `item_type` definition.
    """
    defstruct required: false, checks: [], item_type: nil, type: :list, cast_from: []

    @type t() :: %__MODULE__{
            required: boolean(),
            checks: list(Validator.Rule.t()),
            item_type: Validator.spec_type(),
            type: atom(),
            cast_from: list(atom()) | atom()
          }
  end

  defmodule TupleSpec do
    @moduledoc """
    Represents a tuple.

    Matching values are expected to be a tuple with the same
    size as elem_types, and matching the rule for each element.
    """
    defstruct required: false, checks: [], elem_types: nil, type: :tuple, cast_from: []

    @type t() :: %__MODULE__{
            required: boolean(),
            checks: list(Validator.Rule.t()),
            elem_types: {Validator.spec_type()},
            type: atom(),
            cast_from: list(atom()) | atom()
          }
  end

  defmodule LiteralSpec do
    @moduledoc """
    Represents a literal constant.

    Matching values are expected to be strictly equal to the value.
    """

    defstruct value: nil, required: false, checks: [], type: :any, cast_from: []

    @type t() :: %__MODULE__{
            value: any(),
            required: boolean(),
            checks: list(Validator.Rule.t()),
            type: atom(),
            cast_from: list(atom()) | atom()
          }
  end

  defmodule AnyOtherKey do
    defstruct []

    @type t() :: %__MODULE__{}
  end

  defmacro defvalidator(do: body) do
    quote do
      import Validator
      import Validator.Rule
      import Validator.Helpers

      unquote(body)
    end
  end

  @spec validate(any, spec_type(), Keyword.t()) :: list(Error.t())
  def validate(value, schema, opts \\ []) do
    check_schema = opts |> Keyword.get(:check_schema, true)

    if check_schema do
      case validate_schema(schema) do
        [] -> do_validate(value, schema)
        _else -> raise "Invalid schema"
      end
    else
      do_validate(value, schema)
    end
  end

  @spec validate_schema(any) :: list(Error.t())
  def validate_schema(schema) do
    do_validate(schema, Validator.SchemaValidator.schema_schema())
  end

  defp do_validate(value, schema, context \\ []) do
    case check_type_and_cast_if_needed(value, schema, context) do
      {:ok, cast_value} -> dispatch_validation(cast_value, schema, context)
      {:error, error} -> [Error.new(error, context)]
    end
  end

  defp dispatch_validation(value, schema, context) do
    case schema do
      %ListSpec{} -> validate_list(value, schema, context)
      [item_type] -> validate_list(value, Helpers.list(item_type), context)
      [] -> validate_list(value, Helpers.list(Helpers.value()), context)
      %TupleSpec{} -> validate_tuple(value, schema, context)
      tuple when is_tuple(tuple) -> validate_tuple(value, Helpers.tuple(tuple), context)
      %ValueSpec{} -> validate_value(value, schema, context)
      %LiteralSpec{} -> validate_literal(value, schema, context)
      %{} -> validate_map(value, schema, context)
      func when is_function(func, 0) -> do_validate(value, func.(), context)
      func when is_function(func, 1) -> validate_select(value, func, context)
      literal when is_binary(literal) -> validate_literal(value, Helpers.literal(schema), context)
      literal when is_atom(literal) -> validate_literal(value, Helpers.literal(schema), context)
      literal when is_number(literal) -> validate_literal(value, Helpers.literal(schema), context)
    end
  end

  defp check_type_and_cast_if_needed(
         value,
         %spec_module{type: type, cast_from: cast_from},
         _context
       ) do
    possible_casts =
      cast_from
      |> List.wrap()
      |> Enum.filter(&Types.has_type?(value, &1))

    cond do
      Types.has_type?(value, type) -> {:ok, value}
      possible_casts != [] -> Types.cast(value, List.first(possible_casts), type)
      spec_module != LiteralSpec -> {:error, "Expected type: #{type}, got: #{inspect(value)}."}
      true -> {:ok, value}
    end
  end

  defp check_type_and_cast_if_needed(value, _schema, _context), do: {:ok, value}

  defp validate_map(map, %{} = schema, context) when is_struct(map) do
    validate_map(Map.from_struct(map), schema, context)
  end

  defp validate_map(map, %{} = schema, context) when is_map(map) do
    field_errors =
      schema
      |> Enum.map(fn
        {%AnyOtherKey{}, field} ->
          unexpected_fields(map, schema)
          |> Enum.map(&validate_map_field(map, &1, field, context))

        {field_name, field} ->
          validate_map_field(map, field_name, field, context)
      end)

    [
      unexpected_fields_error(map, schema, context),
      missing_fields_error(map, schema, context),
      field_errors
    ]
    |> List.flatten()
  end

  defp validate_map(map, _spec, context) do
    [Error.new("Expected type: map, got: #{inspect(map)}.", context)]
  end

  defp validate_map_field(map, field_name, field_schema, context) do
    case Map.fetch(map, field_name) do
      :error -> []
      {:ok, value} -> do_validate(value, field_schema, context ++ [field_name])
    end
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
        do_validate(value, spec.item_type, context ++ [index])
      end)
      |> List.flatten()

    [
      top_level_errors,
      items_errors
    ]
    |> List.flatten()
  end

  defp validate_list(list, _spec, context) do
    [Error.new("Expected type: list, got: #{inspect(list)}.", context)]
  end

  defp validate_tuple(tuple, spec, context)
       when is_tuple(tuple) and tuple_size(tuple) == tuple_size(spec.elem_types) do
    top_level_errors =
      spec.checks
      |> Enum.map(fn check -> check.(tuple, context) end)

    elem_errors =
      tuple
      |> Tuple.to_list()
      |> Enum.zip(Tuple.to_list(spec.elem_types))
      |> Enum.with_index()
      |> Enum.map(fn {{value, elem_type}, index} ->
        do_validate(value, elem_type, context ++ [index])
      end)
      |> List.flatten()

    [
      top_level_errors,
      elem_errors
    ]
    |> List.flatten()
  end

  defp validate_tuple(tuple, spec, context) when is_tuple(tuple) do
    expected_size = tuple_size(spec.elem_types)
    actual_size = tuple_size(tuple)

    [
      Error.new(
        "Invalid tuple size (expected: #{expected_size}, received: #{actual_size})",
        context
      )
    ]
  end

  defp validate_tuple(value, _spec, context) do
    [Error.new("Expected type: tuple, got: #{inspect(value)}.", context)]
  end

  defp validate_select(value, func_spec, context) do
    do_validate(value, func_spec.(value), context)
  rescue
    _e in FunctionClauseError ->
      [Error.new("Value does not match any of the possible schemas.", context)]
  end

  defp validate_literal(value, spec, context) do
    if value == spec.value do
      []
    else
      [
        Error.new(
          "Expected literal value #{inspect(spec.value)}, got: #{inspect(value)}.",
          context
        )
      ]
    end
  end

  defp unexpected_fields(map, schema) do
    Map.keys(map) -- Map.keys(schema)
  end

  defp unexpected_fields_error(_map, %{%AnyOtherKey{} => _}, _context), do: []

  defp unexpected_fields_error(map, schema, context) do
    unexpected_fields = unexpected_fields(map, schema)

    if unexpected_fields == [] do
      []
    else
      [Error.new("Unexpected fields: #{inspect(unexpected_fields)}", context)]
    end
  end

  defp missing_fields_error(map, schema, context) do
    missing_fields =
      for {field_name, field} <- schema,
          is_nil(map |> Map.get(field_name)) and required_field?(field) do
        field_name
      end

    if missing_fields == [] do
      []
    else
      [Error.new("Missing required fields: #{inspect(missing_fields)}", context)]
    end
  end

  defp required_field?(field) when is_list(field), do: false
  defp required_field?(field) when is_tuple(field), do: false
  defp required_field?(field) when is_map(field), do: field |> Map.get(:required, false)
  defp required_field?(field) when is_function(field), do: false
end
