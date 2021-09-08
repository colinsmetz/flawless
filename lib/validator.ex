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
  alias Validator.Rule

  @type spec_type() ::
          Validator.ValueSpec.t()
          | Validator.ListSpec.t()
          | Validator.TupleSpec.t()
          | Validator.StructSpec.t()
          | Validator.LiteralSpec.t()
          | map()
          | list()
          | tuple()
          | atom()
          | number()
          | binary()

  defmodule ValueSpec do
    @moduledoc """
    Represents a simple value or a map.

    The `schema` field is used when the value is a map, and is `nil` otherwise.
    """
    defstruct required: false, checks: [], schema: nil, type: :any, cast_from: [], nil: :default

    @type t() :: %__MODULE__{
            required: boolean(),
            checks: list(Validator.Rule.t()),
            schema: map() | nil,
            type: atom(),
            cast_from: list(atom()) | atom(),
            nil: :default | true | false
          }
  end

  defmodule StructSpec do
    @moduledoc """
    Represents a struct.
    """
    defstruct required: false,
              checks: [],
              schema: nil,
              module: nil,
              type: :any,
              cast_from: [],
              nil: :default

    @type t() :: %__MODULE__{
            required: boolean(),
            checks: list(Validator.Rule.t()),
            schema: map() | nil,
            module: atom(),
            type: atom(),
            cast_from: list(atom()) | atom(),
            nil: :default | true | false
          }
  end

  defmodule ListSpec do
    @moduledoc """
    Represents a list of elements.

    Each element must conform to the `item_type` definition.
    """
    defstruct required: false,
              checks: [],
              item_type: nil,
              type: :list,
              cast_from: [],
              nil: :default

    @type t() :: %__MODULE__{
            required: boolean(),
            checks: list(Validator.Rule.t()),
            item_type: Validator.spec_type(),
            type: atom(),
            cast_from: list(atom()) | atom(),
            nil: :default | true | false
          }
  end

  defmodule TupleSpec do
    @moduledoc """
    Represents a tuple.

    Matching values are expected to be a tuple with the same
    size as elem_types, and matching the rule for each element.
    """
    defstruct required: false,
              checks: [],
              elem_types: nil,
              type: :tuple,
              cast_from: [],
              nil: :default

    @type t() :: %__MODULE__{
            required: boolean(),
            checks: list(Validator.Rule.t()),
            elem_types: {Validator.spec_type()},
            type: atom(),
            cast_from: list(atom()) | atom(),
            nil: :default | true | false
          }
  end

  defmodule LiteralSpec do
    @moduledoc """
    Represents a literal constant.

    Matching values are expected to be strictly equal to the value.
    """

    defstruct value: nil, required: false, checks: [], type: :any, cast_from: [], nil: :default

    @type t() :: %__MODULE__{
            value: any(),
            required: boolean(),
            checks: list(Validator.Rule.t()),
            type: atom(),
            cast_from: list(atom()) | atom(),
            nil: :default | true | false
          }
  end

  defmodule AnyOtherKey do
    defstruct []

    @type t() :: %__MODULE__{}
  end

  defmodule OptionalKey do
    defstruct key: nil

    @type t() :: %__MODULE__{
            key: any()
          }
  end

  defmodule Context do
    defstruct path: [], is_optional_field: false

    @type t() :: %__MODULE__{
            path: list(String.t()),
            is_optional_field: boolean()
          }

    def add_to_path(context, path_element) do
      %Context{context | path: context.path ++ [path_element]}
    end
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
        errors -> raise "Invalid schema: #{inspect(errors)}"
      end
    else
      do_validate(value, schema)
    end
    |> Error.evaluate_messages()
  end

  @spec validate_schema(any) :: list(Error.t())
  def validate_schema(schema) do
    do_validate(schema, Validator.SchemaValidator.schema_schema())
    |> Error.evaluate_messages()
  end

  defp do_validate(value, schema, context \\ %Context{}) do
    errors =
      case check_type_and_cast_if_needed(value, schema, context) do
        {:ok, cast_value} ->
          dispatch_validation(cast_value, schema, %{context | is_optional_field: false})

        {:error, error} ->
          [Error.new(error, context)]
      end

    case {value, nil_opt(schema), errors} do
      {nil, true, _} -> []
      {nil, false, _} -> [Error.new("Value cannot be nil.", context)]
      {nil, :default, []} -> []
      {nil, :default, _errors} when context.is_optional_field -> []
      {nil, :default, errors} -> errors
      _ -> errors
    end
  end

  defp nil_opt(%module{nil: nil_opt})
       when module in [ValueSpec, StructSpec, ListSpec, TupleSpec, LiteralSpec] do
    nil_opt
  end

  defp nil_opt(_schema) do
    :default
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
      %StructSpec{} -> validate_struct(value, schema, context)
      %_{} -> validate_struct(value, Helpers.structure(schema), context)
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
      |> Enum.filter(fn
        {type, with: _converter} -> Types.has_type?(value, type)
        type when is_atom(type) -> Types.has_type?(value, type)
      end)

    cond do
      Types.has_type?(value, type) ->
        {:ok, value}

      possible_casts != [] ->
        possible_casts
        |> List.first()
        |> case do
          {from, with: converter} -> Types.cast_with(value, from, converter)
          from when is_atom(from) -> Types.cast(value, from, type)
        end

      spec_module != LiteralSpec ->
        {:error, "Expected type: #{type}, got: #{inspect(value)}."}

      true ->
        {:ok, value}
    end
  end

  defp check_type_and_cast_if_needed(value, _schema, _context), do: {:ok, value}

  defp validate_map(map, %{} = _schema, context) when is_struct(map) do
    [Error.new("Expected type: map, got: struct.", context)]
  end

  defp validate_map(map, %{} = schema, context) when is_map(map) do
    field_errors =
      schema
      |> Enum.map(fn
        {%AnyOtherKey{}, field} ->
          unexpected_fields(map, schema)
          |> Enum.map(&validate_map_field(map, &1, field, context))

        {%OptionalKey{key: field_name}, field} ->
          validate_map_field(map, field_name, field, %{context | is_optional_field: true})

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
    [Error.invalid_type_error(:map, map, context)]
  end

  defp validate_map_field(map, field_name, field_schema, context) do
    case Map.fetch(map, field_name) do
      :error -> []
      {:ok, value} -> do_validate(value, field_schema, context |> Context.add_to_path(field_name))
    end
  end

  defp validate_struct(
         %value_module{} = struct,
         %StructSpec{module: module, schema: schema} = spec,
         context
       )
       when value_module == module do
    top_level_errors =
      spec.checks
      |> Enum.map(&Rule.evaluate(&1, struct, context))

    sub_errors = validate_map(Map.from_struct(struct), Map.from_struct(schema), context)

    [
      top_level_errors,
      sub_errors
    ]
    |> List.flatten()
  end

  defp validate_struct(%value_module{} = _struct, %StructSpec{module: module}, context)
       when value_module != module do
    [
      Error.new(
        {"Expected struct of type: %{expected_module}, got struct of type: %{actual_module}.",
         expected_module: inspect(module), actual_module: inspect(value_module)},
        context
      )
    ]
  end

  defp validate_struct(struct, _spec, context) do
    [Error.invalid_type_error(:struct, struct, context)]
  end

  defp validate_value(value, spec, context) do
    top_level_errors =
      spec.checks
      |> Enum.map(&Rule.evaluate(&1, value, context))

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
      |> Enum.map(&Rule.evaluate(&1, list, context))

    items_errors =
      list
      |> Enum.with_index()
      |> Enum.map(fn {value, index} ->
        do_validate(value, spec.item_type, context |> Context.add_to_path(index))
      end)
      |> List.flatten()

    [
      top_level_errors,
      items_errors
    ]
    |> List.flatten()
  end

  defp validate_list(list, _spec, context) do
    [Error.invalid_type_error(:list, list, context)]
  end

  defp validate_tuple(tuple, spec, context)
       when is_tuple(tuple) and tuple_size(tuple) == tuple_size(spec.elem_types) do
    top_level_errors =
      spec.checks
      |> Enum.map(&Rule.evaluate(&1, tuple, context))

    elem_errors =
      tuple
      |> Tuple.to_list()
      |> Enum.zip(Tuple.to_list(spec.elem_types))
      |> Enum.with_index()
      |> Enum.map(fn {{value, elem_type}, index} ->
        do_validate(value, elem_type, context |> Context.add_to_path(index))
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
        {"Invalid tuple size (expected: %{expected_size}, received: %{actual_size}).",
         expected_size: expected_size, actual_size: actual_size},
        context
      )
    ]
  end

  defp validate_tuple(value, _spec, context) do
    [Error.invalid_type_error(:tuple, value, context)]
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
          {"Expected literal value %{expected_value}, got: %{value}.",
           expected_value: inspect(spec.value), value: inspect(value)},
          context
        )
      ]
    end
  end

  defp unexpected_fields(map, schema) do
    keys_from_schema =
      schema
      |> Map.keys()
      |> Enum.map(fn
        %OptionalKey{key: key} -> key
        key -> key
      end)

    Map.keys(map) -- keys_from_schema
  end

  defp unexpected_fields_error(_map, %{%AnyOtherKey{} => _}, _context), do: []

  defp unexpected_fields_error(map, schema, context) do
    unexpected_fields = unexpected_fields(map, schema)

    if unexpected_fields == [] do
      []
    else
      [
        Error.new(
          {"Unexpected fields: %{unexpected_fields}.",
           unexpected_fields: inspect(unexpected_fields)},
          context
        )
      ]
    end
  end

  defp missing_fields(map, schema) do
    schema
    |> Enum.reject(fn {key, _} ->
      match?(%OptionalKey{}, key) or match?(%AnyOtherKey{}, key)
    end)
    |> Enum.filter(fn {field_name, _field} ->
      not (map |> Map.has_key?(field_name))
      # map |> Map.get(field_name) |> is_nil() # and required_field?(field)
    end)
    |> Enum.map(fn {field_name, _} -> field_name end)
  end

  defp missing_fields_error(map, schema, context) do
    missing_fields = missing_fields(map, schema)

    if missing_fields == [] do
      []
    else
      [
        Error.new(
          {"Missing required fields: %{missing_fields}.",
           missing_fields: show_fields_with_type(schema, missing_fields)},
          context
        )
      ]
    end
  end

  defp show_fields_with_type(schema, fields) do
    fields
    |> Enum.map(fn field ->
      type =
        schema
        |> Map.get(field)
        |> case do
          %module{type: type}
          when module in [ValueSpec, ListSpec, TupleSpec, StructSpec, LiteralSpec] ->
            type

          value ->
            Types.type_of(value)
        end

      "#{inspect(field)} (#{type})"
    end)
    |> Enum.join(", ")
  end
end
