defmodule Validator.SchemaValidator do
  @moduledoc """
  Defines a schema to validate that schemas are valid.
  """
  import Validator.Helpers

  def schema_schema() do
    fn
      %Validator.Spec{} -> spec_schema()
      %Validator.Union{} -> union_schema()
      [] -> literal([])
      l when is_list(l) -> list_schema()
      t when is_tuple(t) -> tuple_schema()
      f when is_function(f, 0) -> function(arity: 0)
      f when is_function(f, 1) -> function(arity: 1)
      %module{} -> struct_schema(module)
      %{} -> map_schema()
      literal when is_binary(literal) -> string()
      literal when is_atom(literal) -> atom()
      literal when is_number(literal) -> number()
    end
  end

  defp union_schema() do
    structure(%Validator.Union{
      schemas: [schema_schema()]
    })
  end

  defp spec_schema() do
    structure(%Validator.Spec{
      checks: checks_schema(),
      type: type_schema(),
      cast_from: cast_from_schema(),
      nil: nil_schema(),
      on_error: on_error_schema(),
      for: fn
        %Validator.Spec.Value{} -> value_spec_schema()
        %Validator.Spec.List{} -> list_spec_schema()
        %Validator.Spec.Tuple{} -> tuple_spec_schema()
        %Validator.Spec.Literal{} -> literal_spec_schema()
        %Validator.Spec.Struct{module: module} -> struct_spec_schema(module)
      end
    })
  end

  defp value_spec_schema() do
    structure(%Validator.Spec.Value{
      schema: fn
        nil -> nil
        _ -> map_schema()
      end
    })
  end

  defp struct_spec_schema(module) do
    structure(%Validator.Spec.Struct{
      module: atom(),
      schema: struct_schema(module)
    })
  end

  defp list_spec_schema() do
    structure(%Validator.Spec.List{
      item_type: &schema_schema/0
    })
  end

  defp tuple_spec_schema() do
    structure(%Validator.Spec.Tuple{
      elem_types: list(&schema_schema/0, cast_from: :tuple)
    })
  end

  defp literal_spec_schema() do
    structure(%Validator.Spec.Literal{
      value: value()
    })
  end

  defp list_schema() do
    list(&schema_schema/0,
      max_length: 1,
      on_error:
        "The list shortcut `[item_spec]` should define only one schema that will be the same for all items."
    )
  end

  defp tuple_schema() do
    list(&schema_schema/0, cast_from: :tuple)
  end

  defp map_schema() do
    %{any_key() => &schema_schema/0}
  end

  defp struct_schema(module) do
    structure(
      %{
        any_key() => &schema_schema/0,
        __struct__: module
      },
      nil: true
    )
  end

  defp type_schema() do
    atom(in: Validator.Types.valid_types())
  end

  defp checks_schema() do
    list(check_schema())
  end

  defp check_schema() do
    fn
      %_{} ->
        structure(%Validator.Rule{
          predicate: predicate_schema(),
          message: value()
        })

      _else ->
        predicate_schema()
    end
  end

  defp predicate_schema() do
    function(arity: 1, on_error: "Predicates used in checks must be function of arity 1.")
  end

  defp cast_from_schema() do
    fn
      l when is_list(l) -> list(&cast_from_schema/0)
      {_type, [with: _converter]} -> {type_schema(), list({:with, function()}, length: 1)}
      _ -> type_schema()
    end
  end

  defp nil_schema() do
    atom(in: [:default, true, false])
  end

  defp on_error_schema() do
    fn
      nil -> nil
      _ -> string()
    end
  end
end
