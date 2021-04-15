defmodule Validator.Error do
  defstruct [context: [], message: ""]

  def new(message, context) do
    %__MODULE__{
      message: message,
      context: context
    }
  end
end