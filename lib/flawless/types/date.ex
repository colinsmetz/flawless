defmodule Flawless.Types.Date do
  alias Flawless.Helpers
  alias Flawless.Rule

  def date(opts \\ []) do
    Helpers.opaque_struct_type(
      Date,
      opts,
      converter: &cast_from/2,
      shortcut_rules: [
        after: &after_date/1,
        before: &before_date/1,
        between: &between_dates/2
      ]
    )
  end

  def after_date(date) do
    Rule.rule(
      fn value -> Date.compare(value, date) in [:gt, :eq] end,
      "The date should be later than #{date}."
    )
  end

  def before_date(date) do
    Rule.rule(
      fn value -> Date.compare(value, date) in [:lt, :eq] end,
      "The date should be earlier than #{date}."
    )
  end

  def between_dates(date1, date2) do
    Rule.rule(
      fn value ->
        Date.compare(value, date1) in [:gt, :eq] and
          Date.compare(value, date2) in [:lt, :eq]
      end,
      "The date should be comprised between #{date1} and #{date2}."
    )
  end

  defp cast_from(value, :string) do
    value
    |> Date.from_iso8601()
    |> case do
      {:ok, date} -> {:ok, date}
      _ -> :error
    end
  end

  defp cast_from(value, :integer) do
    {:ok, value |> Date.from_gregorian_days()}
  rescue
    _ -> :error
  end

  defp cast_from(_value, _type), do: :error
end
