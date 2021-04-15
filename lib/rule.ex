defmodule Validator.Rule do
  def rule(predicate, error_message) do
    fn field_name, value ->
      if predicate.(value) do
        []
      else
        if is_binary(error_message) do
          error_message
        else
          error_message.(field_name, value)
        end
      end
    end
  end

  def one_of(options) do
    rule(
      &(&1 in options),
      &"Invalid value #{&2} for #{&1}. Valid options: #{inspect(options)}"
    )
  end

  def is_integer_type() do
    rule(
      &is_integer/1,
      &"Field #{&1} must be an integer. Received: #{inspect(&2)}."
    )
  end

  def is_string_type() do
    rule(
      &is_binary/1,
      &"Field #{&1} must be a string. Received: #{inspect(&2)}."
    )
  end

  def is_float_type() do
    rule(
      &is_float/1,
      &"Field #{&1} must be a float. Received: #{inspect(&2)}."
    )
  end

  def is_number_type() do
    rule(
      &is_number/1,
      &"Field #{&1} must be a number. Received: #{inspect(&2)}."
    )
  end

  def is_boolean_type() do
    rule(
      &is_boolean/1,
      &"Field #{&1} must be a boolean. Received: #{inspect(&2)}."
    )
  end
end
