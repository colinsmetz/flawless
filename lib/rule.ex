defmodule Validator.Rule do
  @type t() :: (any, list -> [] | Validator.Error.t())

  @type predicate() :: (any -> boolean())
  @type error_function() :: String.t() | (any -> String.t()) | (any, list -> String.t())

  @spec rule(predicate(), error_function()) :: t()
  def rule(predicate, error_message) do
    fn value, context ->
      cond do
        predicate.(value) -> []
        is_binary(error_message) -> error_message
        is_function(error_message, 1) -> error_message.(value)
        is_function(error_message, 2) -> error_message.(value, context)
      end
      |> case do
        [] -> []
        error -> Validator.Error.new(error, context)
      end
    end
  end

  @spec one_of(list) :: t()
  def one_of(options) when is_list(options) do
    rule(
      &(&1 in options),
      &"Invalid value '#{&1}'. Valid options: #{inspect(options)}"
    )
  end

  @spec is_integer_type :: t()
  def is_integer_type() do
    rule(
      &is_integer/1,
      &"Expected an integer, received: #{inspect(&1)}."
    )
  end

  @spec is_string_type :: t()
  def is_string_type() do
    rule(
      &is_binary/1,
      &"Expected a string, received: #{inspect(&1)}."
    )
  end

  @spec is_float_type :: t()
  def is_float_type() do
    rule(
      &is_float/1,
      &"Expected a float, received: #{inspect(&1)}."
    )
  end

  @spec is_number_type :: t()
  def is_number_type() do
    rule(
      &is_number/1,
      &"Expected a number, received: #{inspect(&1)}."
    )
  end

  @spec is_boolean_type :: t()
  def is_boolean_type() do
    rule(
      &is_boolean/1,
      &"Expected a boolean, received: #{inspect(&1)}."
    )
  end

  @spec is_atom_type :: t()
  def is_atom_type() do
    rule(
      &is_atom/1,
      &"Expected an atom, received: #{inspect(&1)}."
    )
  end

  defp value_length(value) when is_binary(value), do: String.length(value)
  defp value_length(value) when is_list(value), do: length(value)
  defp value_length(_), do: nil

  @spec min_length(integer()) :: t()
  def min_length(length) when is_integer(length) do
    rule(
      fn value ->
        case value_length(value) do
          nil -> true
          actual_length -> actual_length >= length
        end
      end,
      &"Minimum length of #{length} required (current: #{value_length(&1)})."
    )
  end

  @spec max_length(integer()) :: t()
  def max_length(length) when is_integer(length) do
    rule(
      fn value ->
        case value_length(value) do
          nil -> true
          actual_length -> actual_length <= length
        end
      end,
      &"Maximum length of #{length} required (current: #{value_length(&1)})."
    )
  end

  @spec non_empty() :: t()
  def non_empty() do
    rule(
      fn value ->
        case value_length(value) do
          nil -> true
          actual_length -> actual_length > 0
        end
      end,
      "Value cannot be empty."
    )
  end

  @spec exact_length(integer()) :: t()
  def exact_length(length) when is_integer(length) do
    rule(
      fn value ->
        case value_length(value) do
          nil -> true
          actual_length -> actual_length == length
        end
      end,
      &"Expected length of #{length} (current: #{value_length(&1)})."
    )
  end

  defp duplicates(list) when is_list(list) do
    Enum.uniq(list -- Enum.uniq(list))
  end

  @spec no_duplicate() :: t()
  def no_duplicate() do
    rule(
      fn value -> duplicates(value) == [] end,
      &"The list should not contain duplicates (duplicates found: #{inspect(duplicates(&1))})."
    )
  end

  @spec match(String.t() | Regex.t()) :: t()
  def match(regex) when is_binary(regex) do
    regex
    |> Regex.compile!()
    |> match()
  end

  def match(%Regex{} = regex) do
    rule(
      fn value -> Regex.match?(regex, value) end,
      &"Value #{&1} does not match regex #{inspect(regex)}."
    )
  end

  @spec min(number) :: t()
  def min(min_value) when is_number(min_value) do
    rule(
      fn value -> value >= min_value end,
      "Must be greater than or equal to #{min_value}."
    )
  end

  @spec max(number) :: t()
  def max(max_value) when is_number(max_value) do
    rule(
      fn value -> value <= max_value end,
      "Must be less than or equal to #{max_value}."
    )
  end

  @spec between(number, number) :: t()
  def between(min, max) when is_number(min) and is_number(max) do
    rule(
      fn value -> value >= min and value <= max end,
      "Must be between #{min} and #{max}."
    )
  end
end
