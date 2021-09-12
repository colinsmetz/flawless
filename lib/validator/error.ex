defmodule Validator.Error do
  defstruct context: [], message: ""

  alias Validator.Context

  @type t_message :: String.t() | {String.t(), Keyword.t()}

  @type t() :: %__MODULE__{
          context: list(),
          message: t_message
        }

  @spec new(t_message, Context.t() | list()) :: t()
  def new(message, %Context{} = context) do
    new(message, context.path)
  end

  def new(message, path) when is_list(path) do
    %__MODULE__{
      message: message,
      context: path
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

  @spec invalid_type_error(Validator.Types.t(), any, Context.t()) :: Validator.Error.t()
  def invalid_type_error(expected_type, value, %Context{} = context) do
    new(
      {"Expected type: %{expected_type}, got: %{value}.",
       expected_type: expected_type, value: inspect(value)},
      context
    )
  end
end
