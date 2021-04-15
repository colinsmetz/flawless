defmodule ValidatorTest do
  use ExUnit.Case
  doctest Validator
  import Validator
  import Validator.Rule

  defp required_if_is_key() do
    rule(
      fn field -> not (field["is_key"] == true and not field["is_required"]) end,
      fn field -> "Field '#{field["name"]}' is a key but is not required" end
    )
  end

  test "it works" do
    map = %{
      "format" => "yml",
      "regex" => "/the/regex",
      "options" => %{"a" => "b"},
      "bim" => %{},
      "fields" => [
        %{"name" => "a", "type" => "INT64", "is_key" => true, "is_required" => false},
        %{"name" => "b", "type" => "STRING", "tru" => "blop", "meta" => %{}}
      ],
      "polling" => %{
        "slice_size" => "50MB",
        "interval_seconds" => "12",
        "timeout_ms" => "34567"
      },
      "file_max_age_days" => "67",
      "brands" => ["hey", 28]
    }

    schema = %{
      "format" => req_string(checks: [one_of(["csv", "xml"])]),
      "banana" => req_value(),
      "regex" => req_string(),
      "bim" => %{
        "truc" => req_string()
      },
      "polling" =>
        map(%{
          "slice_size" =>
            value(
              checks: [rule(&(String.length(&1) > 100), "Slice size must be longer than 100")]
            )
        }),
      "fields" =>
        list(
          map(
            %{
              "name" => req_string(),
              "type" => req_string(),
              "is_key" => boolean(),
              "is_required" => boolean(),
              "meta" =>
                map(%{
                  "id" => req_value()
                })
            },
            checks: [required_if_is_key()]
          ),
          checks: [rule(&length(&1) > 0, "Fields must contain at least one item")]
        ),
      "brands" => [string()]
    }

    Validator.validate(map, schema) |> IO.inspect()
  end

  test "it works with basic type" do
    value = "14"
    schema = integer()
    Validator.validate(value, schema) |> IO.inspect()
  end

  test "it works with list type" do
    value = ["yo"]
    schema = list(integer())
    Validator.validate(value, schema) |> IO.inspect()
  end

  test "it works with list type, using shortcut" do
    value = ["yo"]
    schema = [integer()]
    Validator.validate(value, schema) |> IO.inspect()
  end

  test "yo" do
    map = %{
      "format" => "yml",
      "fields" => [
        %{"name" => "a", "type" => "INT64", "is_key" => true, "is_required" => false},
        %{"name" => "b", "type" => "STRING"}
      ],
      "polling" => %{
        "slice_size" => "50MB",
        "interval_seconds" => "12",
        "timeout_ms" => "34567"
      },
      "plop" => 14
    }

    schema = %{
      "format" => req_string(checks: [one_of(["csv", "xml"])]),
      "regex" => req_string(),
      "polling" =>
        map(%{
          "slice_size" => value()
        }),
      "fields" =>
        list(
          map(
            %{
              "name" => req_string(),
              "type" => req_string(),
              "is_key" => boolean(),
              "is_required" => boolean()
            },
            checks: [required_if_is_key()]
          ),
          checks: [rule(&length(&1) > 0, "Fields must contain at least one item")]
        )
    }

    Validator.validate(map, schema) |> IO.inspect()
  end
end
