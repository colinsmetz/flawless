defmodule Validator.Utils.Enum do
  @spec collect_errors(any, boolean, function()) :: any
  def collect_errors(enumerable, stop_early \\ false, collect_func) do
    enumerable
    |> Enum.reduce_while([], fn item, errors ->
      new_errors = collect_func.(item)

      if stop_early and new_errors != [] do
        {:halt, new_errors}
      else
        {:cont, new_errors ++ errors}
      end
    end)
  end
end
