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

  @spec maybe_add_errors(list(Validator.Error.t()), boolean(), function()) ::
          list(Validator.Error.t())
  def maybe_add_errors([], _stop_early, collect_func) do
    collect_func.()
  end

  def maybe_add_errors(errors, false = _stop_early, collect_func) do
    [
      errors,
      collect_func.()
    ]
    |> List.flatten()
  end

  def maybe_add_errors(errors, true = _stop_early, _collect_func) do
    errors
  end
end
