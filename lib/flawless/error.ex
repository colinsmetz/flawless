defmodule Flawless.Error do
  @moduledoc """
  Provides the Error struct, and helpers for building and converting errors.
  """

  defstruct context: [], message: ""

  alias Flawless.Context
  import Flawless.Utils.Interpolation, only: [sigil_t: 2]

  @type t_message :: String.t() | {String.t() | list(), Keyword.t()} | list(String.t())

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
    Flawless.Utils.Interpolation.from_template(message, opts)
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

  @spec invalid_type_error(Flawless.Types.t(), any, Context.t()) :: Flawless.Error.t()
  def invalid_type_error(expected_type, value, %Context{} = context) do
    new(
      {~t"Expected type: %{expected_type}, got: %{value}.",
       expected_type: expected_type, value: inspect(value)},
      context
    )
  end

  @spec group_by_path(list(t())) :: list(t())
  def group_by_path(errors) when is_list(errors) do
    errors
    |> Enum.group_by(& &1.context, & &1.message)
    |> Enum.map(fn
      {context, [message]} -> new(message, context)
      {context, messages} -> new(messages, context)
    end)
  end
end
