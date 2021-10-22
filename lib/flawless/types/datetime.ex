defmodule Flawless.Types.DateTime do
  alias Flawless.Helpers
  alias Flawless.Rule

  def datetime(opts \\ []) do
    Helpers.opaque_struct_type(
      DateTime,
      opts,
      converter: &cast_from/2,
      shortcut_rules: [
        after: &after_datetime/1,
        before: &before_datetime/1,
        between: &between_datetimes/2
      ]
    )
  end

  def after_datetime(datetime) do
    Rule.rule(
      fn value -> DateTime.compare(value, datetime) in [:gt, :eq] end,
      "The datetime should be later than #{datetime}."
    )
  end

  def before_datetime(datetime) do
    Rule.rule(
      fn value -> DateTime.compare(value, datetime) in [:lt, :eq] end,
      "The datetime should be earlier than #{datetime}."
    )
  end

  def between_datetimes(datetime1, datetime2) do
    Rule.rule(
      fn value ->
        DateTime.compare(value, datetime1) in [:gt, :eq] and
          DateTime.compare(value, datetime2) in [:lt, :eq]
      end,
      "The datetime should be comprised between #{datetime1} and #{datetime2}."
    )
  end

  defp cast_from(value, :string) do
    value
    |> DateTime.from_iso8601()
    |> case do
      {:ok, datetime, _} -> {:ok, datetime}
      _ -> :error
    end
  end

  defp cast_from(value, :integer) do
    value
    |> DateTime.from_unix()
    |> case do
      {:ok, datetime} -> {:ok, datetime}
      _ -> :error
    end
  end

  defp cast_from(_value, _type), do: :error
end
