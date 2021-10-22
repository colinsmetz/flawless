defmodule Flawless.Rule do
  @moduledoc """
  Provides helpers to build and evaluate rules. It also defines all the built-in rules.
  """

  defstruct predicate: nil, message: nil

  alias Flawless.Context

  @type predicate() :: (any -> boolean())
  @type error_function() ::
          Flawless.Error.t_message()
          | (any -> Flawless.Error.t_message())
          | (any, list -> Flawless.Error.t_message())

  @type t() :: %__MODULE__{
          predicate: function(),
          message: error_function() | nil
        }

  @spec rule(predicate(), error_function() | nil) :: Flawless.Rule.t()
  def rule(predicate, error_message \\ nil) do
    %__MODULE__{
      predicate: predicate,
      message: error_message
    }
  end

  @spec evaluate(Flawless.Rule.t() | function(), any, Context.t()) :: [] | Flawless.Error.t()
  def evaluate(%__MODULE__{predicate: predicate, message: error_message} = _rule, data, context) do
    do_evaluate(predicate, error_message, data, context)
  end

  def evaluate(predicate, data, context) do
    do_evaluate(predicate, nil, data, context)
  end

  defp do_evaluate(predicate, error_message, data, context) do
    case predicate_result(predicate, data) do
      :ok ->
        []

      {:error, error} ->
        Flawless.Error.new(error, context)

      :error ->
        error_message
        |> evaluate_error_message(data, context)
        |> Flawless.Error.new(context)
    end
  rescue
    _ -> error_on_exception(context)
  end

  def predicate_result(predicate, data) do
    case predicate.(data) do
      true -> :ok
      false -> :error
      :ok -> :ok
      :error -> :error
      {:ok, _} -> :ok
      {:error, error} -> {:error, error}
    end
  end

  defp evaluate_error_message(error_message, data, context) do
    cond do
      is_nil(error_message) -> "The predicate failed."
      is_binary(error_message) -> error_message
      is_tuple(error_message) -> error_message
      is_function(error_message, 1) -> error_message.(data)
      is_function(error_message, 2) -> error_message.(data, context)
    end
  end

  defp error_on_exception(context) do
    Flawless.Error.new(
      "An exception was raised while evaluating a rule on that element, so it is likely incorrect.",
      context
    )
  end

  @spec one_of(list) :: t()
  def one_of(options) when is_list(options) do
    rule(
      &(&1 in options),
      &{"Invalid value: %{value}. Valid options: %{options}",
       value: inspect(&1), options: inspect(options)}
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
      &{"Minimum length of %{min_length} required (current: %{actual_length}).",
       min_length: length, actual_length: value_length(&1)}
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
      &{"Maximum length of %{max_length} required (current: %{actual_length}).",
       max_length: length, actual_length: value_length(&1)}
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
      &{"Expected length of %{expected_length} (current: %{actual_length}).",
       expected_length: length, actual_length: value_length(&1)}
    )
  end

  defp duplicates(list) when is_list(list) do
    Enum.uniq(list -- Enum.uniq(list))
  end

  @spec no_duplicate() :: t()
  def no_duplicate() do
    rule(
      fn value -> duplicates(value) == [] end,
      &{"The list should not contain duplicates (duplicates found: %{duplicates}).",
       duplicates: inspect(duplicates(&1))}
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
      &{"Value %{value} does not match regex %{regex}.",
       value: inspect(&1), regex: inspect(regex)}
    )
  end

  @spec min(number) :: t()
  def min(min_value) when is_number(min_value) do
    rule(
      fn value -> value >= min_value end,
      {"Must be greater than or equal to %{min_value}.", min_value: min_value}
    )
  end

  @spec max(number) :: t()
  def max(max_value) when is_number(max_value) do
    rule(
      fn value -> value <= max_value end,
      {"Must be less than or equal to %{max_value}.", max_value: max_value}
    )
  end

  @spec between(number, number) :: t()
  def between(min, max) when is_number(min) and is_number(max) do
    rule(
      fn value -> value >= min and value <= max end,
      {"Must be between %{min_value} and %{max_value}.", min_value: min, max_value: max}
    )
  end

  @spec not_both(any, any) :: t()
  def not_both(field1, field2) do
    rule(
      fn map -> not (field1 in Map.keys(map) and field2 in Map.keys(map)) end,
      {"Fields %{field1} and %{field2} cannot both be defined.", field1: field1, field2: field2}
    )
  end

  defp get_arity(func) do
    func
    |> Function.info()
    |> Keyword.get(:arity, 0)
  end

  @spec arity(integer) :: t()
  def arity(arity) do
    rule(
      fn func -> get_arity(func) == arity end,
      &{"Expected arity of %{expected_arity}, found: %{actual_arity}.",
       expected_arity: arity, actual_arity: get_arity(&1)}
    )
  end
end
