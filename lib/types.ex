defmodule Validator.Types do
  @type t() ::
          :any
          | :string
          | :number
          | :integer
          | :float
          | :boolean
          | :atom
          | :pid
          | :ref
          | :list
          | :tuple
          | :map

  @spec has_type?(any, t()) :: boolean
  def has_type?(value, expected_type) do
    case expected_type do
      :any -> true
      :string -> is_binary(value)
      :number -> is_number(value)
      :integer -> is_integer(value)
      :float -> is_float(value)
      :boolean -> is_boolean(value)
      :atom -> is_atom(value)
      :pid -> is_pid(value)
      :ref -> is_reference(value)
      :list -> is_list(value)
      :tuple -> is_tuple(value)
      :map -> is_map(value)
    end
  end

  @spec type_of(any) :: t()
  def type_of(value) do
    cond do
      is_binary(value) -> :string
      is_float(value) -> :float
      is_integer(value) -> :integer
      is_number(value) -> :number
      is_boolean(value) -> :boolean
      is_atom(value) -> :atom
      is_pid(value) -> :pid
      is_reference(value) -> :ref
      is_list(value) -> :list
      is_tuple(value) -> :tuple
      is_map(value) -> :map
      true -> :any
    end
  end

  @spec cast(any, t(), t()) :: {:ok, any} | {:error, String.t()}
  def cast(value, from, to) do
    case do_cast(value, from, to) do
      {:ok, value} -> {:ok, value}
      :error -> {:error, "Cannot be cast to #{to}."}
    end
  end

  defp do_cast(value, from, to) when from == to do
    {:ok, value}
  end

  defp do_cast(value, :string, :number) do
    case {Float.parse(value), Integer.parse(value)} do
      {_, {int, ""}} -> {:ok, int}
      {{float, ""}, _} -> {:ok, float}
      _else -> :error
    end
  end

  defp do_cast(value, :string, :integer) do
    case Integer.parse(value) do
      {int, ""} -> {:ok, int}
      _else -> :error
    end
  end

  defp do_cast(value, :string, :float) do
    case Float.parse(value) do
      {float, ""} -> {:ok, float}
      _else -> :error
    end
  end

  defp do_cast(value, :string, :boolean) do
    case String.downcase(value) do
      "true" -> {:ok, true}
      "false" -> {:ok, false}
      _else -> :error
    end
  end

  defp do_cast(value, :string, :atom), do: {:ok, String.to_atom(value)}
  defp do_cast(value, :number, :integer), do: {:ok, round(value)}
  defp do_cast(value, :number, :float), do: {:ok, value / 1}
  defp do_cast(value, :number, :string), do: {:ok, to_string(value)}
  defp do_cast(value, :integer, :float), do: {:ok, value / 1}
  defp do_cast(value, :integer, :number), do: {:ok, value}
  defp do_cast(value, :integer, :string), do: {:ok, Integer.to_string(value)}
  defp do_cast(value, :float, :integer), do: {:ok, round(value)}
  defp do_cast(value, :float, :number), do: {:ok, value}
  defp do_cast(value, :float, :string), do: {:ok, Float.to_string(value)}
  defp do_cast(value, :boolean, :string), do: {:ok, to_string(value)}
  defp do_cast(value, :atom, :string), do: {:ok, Atom.to_string(value)}
  defp do_cast(value, :list, :tuple), do: {:ok, List.to_tuple(value)}
  defp do_cast(value, :tuple, :list), do: {:ok, Tuple.to_list(value)}
  defp do_cast(_, _, _), do: :error
end
