defmodule Validator.SchemaValidator do
  import Validator.Helpers

  def schema_schema() do
    fn
      %Validator.ValueSpec{} -> value_spec_schema()
      %Validator.ListSpec{} -> list_spec_schema()
      %Validator.TupleSpec{} -> tuple_spec_schema()
      %Validator.LiteralSpec{} -> literal_spec_schema()
      [] -> literal([])
      l when is_list(l) -> list_schema()
      t when is_tuple(t) -> tuple_schema()
      f when is_function(f, 0) -> function(arity: 0)
      f when is_function(f, 1) -> function(arity: 1)
      %{} -> map_schema()
      literal when is_binary(literal) -> string()
      literal when is_atom(literal) -> atom()
      literal when is_number(literal) -> number()
    end
  end

  defp value_spec_schema() do
    %{
      required: boolean(),
      checks: checks_schema(),
      schema: fn
        nil -> nil
        _ -> map_schema()
      end,
      type: type_schema(),
      cast_from: cast_from_schema()
    }
  end

  defp list_spec_schema() do
    %{
      required: boolean(),
      checks: checks_schema(),
      item_type: &schema_schema/0,
      type: :list,
      cast_from: cast_from_schema()
    }
  end

  defp tuple_spec_schema() do
    %{
      required: boolean(),
      checks: checks_schema(),
      elem_types: list(&schema_schema/0, cast_from: :tuple),
      type: :tuple,
      cast_from: cast_from_schema()
    }
  end

  defp literal_spec_schema() do
    %{
      value: value(),
      required: boolean(),
      checks: checks_schema(),
      type: type_schema(),
      cast_from: cast_from_schema()
    }
  end

  defp list_schema() do
    list(&schema_schema/0, max_length: 1)
  end

  defp tuple_schema() do
    list(&schema_schema/0, cast_from: :tuple)
  end

  defp map_schema() do
    %{any_key() => &schema_schema/0}
  end

  defp type_schema() do
    atom(in: Validator.Types.valid_types())
  end

  defp checks_schema() do
    list(function(arity: 2))
  end

  defp cast_from_schema() do
    fn
      l when is_list(l) -> list(type_schema())
      _ -> type_schema()
    end
  end
end
