defmodule Flawless.Types.NaiveDateTime do
  alias Flawless.Helpers
  alias Flawless.Rule

  def naive_datetime(opts \\ []) do
    Helpers.opaque_struct_type(
      NaiveDateTime,
      opts,
      converter: &cast_from/2,
      shortcut_rules: [
        after: &after_naive_datetime/1,
        before: &before_naive_datetime/1,
        between: &between_naive_datetimes/2
      ]
    )
  end

  def after_naive_datetime(datetime) do
    Rule.rule(
      fn value -> NaiveDateTime.compare(value, datetime) in [:gt, :eq] end,
      "The naive datetime should be later than #{datetime}."
    )
  end

  def before_naive_datetime(datetime) do
    Rule.rule(
      fn value -> NaiveDateTime.compare(value, datetime) in [:lt, :eq] end,
      "The naive datetime should be earlier than #{datetime}."
    )
  end

  def between_naive_datetimes(datetime1, datetime2) do
    Rule.rule(
      fn value ->
        NaiveDateTime.compare(value, datetime1) in [:gt, :eq] and
          NaiveDateTime.compare(value, datetime2) in [:lt, :eq]
      end,
      "The naive datetime should be comprised between #{datetime1} and #{datetime2}."
    )
  end

  defp cast_from(value, :string) do
    value
    |> NaiveDateTime.from_iso8601()
    |> case do
      {:ok, datetime} -> {:ok, datetime}
      _ -> :error
    end
  end

  defp cast_from(value, :integer) do
    {:ok, NaiveDateTime.from_gregorian_seconds(value)}
  rescue
    _ -> :error
  end

  defp cast_from(_value, _type), do: :error
end
