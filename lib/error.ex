defmodule Validator.Error do
  defstruct [context: [], message: ""]

  @type t() :: %__MODULE__{
    context: list(),
    message: String.t()
  }

  @spec new(String.t(), list()) :: t()
  def new(message, context) do
    %__MODULE__{
      message: message,
      context: context
    }
  end
end
