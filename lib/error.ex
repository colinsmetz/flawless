defmodule Validator.Error do
  defstruct context: [], message: ""

  @type t_message :: String.t() | {String.t(), Keyword.t()}

  @type t() :: %__MODULE__{
          context: list(),
          message: t_message
        }

  @spec new(t_message, list()) :: t()
  def new(message, context) when is_list(context) do
    %__MODULE__{
      message: message,
      context: context
    }
  end

  @spec message_from_template(String.t(), Keyword.t()) :: String.t()
  def message_from_template(message, opts) do
    Regex.replace(~r"%{(\w+)}", message, fn _, key ->
      opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
    end)
  end

  @spec evaluate_messages(list(t())) :: list(t())
  def evaluate_messages(errors) when is_list(errors) do
    errors
    |> Enum.map(fn
      %{message: message} = error when is_binary(message) ->
        error

      %{message: {template, opts}} = error ->
        %{error | message: message_from_template(template, opts)}
    end)
  end

  @spec invalid_type_error(Validator.Types.t(), any, list) :: Validator.Error.t()
  def invalid_type_error(expected_type, value, context) do
    new(
      {"Expected type: %{expected_type}, got: %{value}.",
       expected_type: expected_type, value: inspect(value)},
      context
    )
  end
end
