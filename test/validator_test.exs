defmodule ValidatorTest do
  use ExUnit.Case
  doctest Validator
  import Validator
  import Validator.Rule

  defp required_if_is_key() do
    rule(
      fn field -> not (field["is_key"] == true and not field["is_required"]) end,
      fn _, field -> "Field '#{field["name"]}' is a key but is not required" end
    )
  end

  test "it works" do
    map = %{
      "format" => "yml",
      "regex" => "/the/regex",
      "options" => %{"a" => "b"},
      "fields" => [
        %{"name" => "a", "type" => "INT64", "is_key" => true, "is_required" => false},
        %{"name" => "b", "type" => "STRING", "tru" => "blop", "meta" => %{}}
      ],
      # "polling" => %{
      #   "slice_size" => "50MB",
      #   "interval_seconds" => "12",
      #   "timeout_ms" => "34567"
      # },
      "file_max_age_days" => "67"
    }

    schema = %{
      "format" => req_string(checks: [one_of(["csv", "xml"])]),
      "banana" => req_field(),
      "regex" => req_string(),
      "polling" =>
        map(%{
          "slice_size" =>
            field(
              checks: [rule(&(String.length(&1) > 100), "Slice size must be longer than 100")]
            )
        }),
      "fields" =>
        list(
          schema: %{
            "name" => req_string(),
            "type" => req_string(),
            "is_key" => boolean(),
            "is_required" => boolean(),
            "meta" =>
              field(
                schema: %{
                  "id" => req_field()
                }
              )
          },
          checks: [required_if_is_key()]
        )
    }

    Validator.validate(map, schema) |> Enum.map(&IO.puts/1)
  end
end

# %{
#   "format" => required_string([one_of(["csv", "xml"])]),
#   "banana" => required_field(),
#   "regex" => required_field(),
#   "polling" => required_map(%{
#       "slice_size" => required_string([rule(&(String.length(&1) > 100), "Slice size must be longer than 100")]),
#     }
#   ),
#   "fields" => list(
#     map(%{
#       "name" => field(required: true),
#       "type" => field(required: true),
#       "is_key" => field([]),
#       "is_required" => field([]),
#       "meta" => field(
#         schema: %{
#           "id" => field(required: true)
#         }
#       )
#     }),
#     checks: [required_if_is_key()]
#   )
# }

# list of basic types ?
# list(field(), checks: [not_empty()])
# list(int([greater_than(6)]))

# list as root ?
# Basic type as root ?
