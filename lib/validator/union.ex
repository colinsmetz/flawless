defmodule Validator.Union do
  @moduledoc """
  Represents the union of multiple schemas.
  """
  defstruct schemas: []

  @type t() :: %__MODULE__{
          schemas: [Validator.spec_type()]
        }

  @spec flatten(list()) :: list()
  def flatten(schemas) do
    schemas
    |> Enum.map(fn
      %__MODULE__{schemas: subschemas} -> flatten(subschemas)
      schema -> [schema]
    end)
    |> Enum.concat()
    |> Enum.uniq()
  end
end
