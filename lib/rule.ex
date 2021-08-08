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
end
