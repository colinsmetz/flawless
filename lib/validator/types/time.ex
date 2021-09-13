defmodule Validator.Types.Time do
  alias Validator.Helpers
  alias Validator.Rule

  def time(opts \\ []) do
    Helpers.opaque_struct_type(
      Time,
      opts,
      converter: &cast_from/2,
      shortcut_rules: [
        after: &after_time/1,
        before: &before_time/1,
        between: &between_times/2
      ]
    )
  end

  def after_time(time) do
    Rule.rule(
      fn value -> Time.compare(value, time) in [:gt, :eq] end,
      "The time should be later than #{time}."
    )
  end

  def before_time(time) do
    Rule.rule(
      fn value -> Time.compare(value, time) in [:lt, :eq] end,
      "The time should be earlier than #{time}."
    )
  end

  def between_times(time1, time2) do
    Rule.rule(
      fn value ->
        if Time.compare(time1, time2) == :lt do
          Time.compare(value, time1) in [:gt, :eq] and
            Time.compare(value, time2) in [:lt, :eq]
        else
          Time.compare(value, time1) in [:gt, :eq] or
            Time.compare(value, time2) in [:lt, :eq]
        end
      end,
      "The time should be comprised between #{time1} and #{time2}."
    )
  end

  defp cast_from(value, :string) do
    value
    |> Time.from_iso8601()
    |> case do
      {:ok, time} -> {:ok, time}
      _ -> :error
    end
  end

  defp cast_from(value, :integer) do
    {:ok, value |> Time.from_seconds_after_midnight()}
  rescue
    _ -> :error
  end

  defp cast_from(_value, _type), do: :error
end
