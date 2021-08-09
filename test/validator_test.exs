defmodule ValidatorTest do
  use ExUnit.Case, async: true
  doctest Validator
  import Validator, only: [defvalidator: 1, validate: 2]
  alias Validator.Error

  describe "basic types" do
    import Validator.Helpers

    test "value/1 expects any value" do
      assert validate(123, value()) == []
      assert validate(true, value()) == []
      assert validate("hey", value()) == []
    end

    test "req_value/1 expects any value" do
      assert validate(123, req_value()) == []
      assert validate(true, req_value()) == []
      assert validate("hey", req_value()) == []
    end

    test "boolean/1 expects a boolean value" do
      assert validate(123, boolean()) == [Error.new("Expected a boolean, received: 123.", [])]
      assert validate(true, boolean()) == []
      assert validate(false, boolean()) == []
    end

    test "req_boolean/1 expects a boolean value" do
      assert validate(123, req_boolean()) == [Error.new("Expected a boolean, received: 123.", [])]
      assert validate(true, req_boolean()) == []
      assert validate(false, req_boolean()) == []
    end

    test "number/1 expects a number value" do
      assert validate("hello", number()) == [
               Error.new("Expected a number, received: \"hello\".", [])
             ]

      assert validate(123, number()) == []
      assert validate(1.44, number()) == []
    end

    test "req_number/1 expects a number value" do
      assert validate("hello", req_number()) == [
               Error.new("Expected a number, received: \"hello\".", [])
             ]

      assert validate(123, req_number()) == []
      assert validate(1.44, req_number()) == []
    end

    test "float/1 expects a float value" do
      assert validate("hello", float()) == [
               Error.new("Expected a float, received: \"hello\".", [])
             ]

      assert validate(123, float()) == [
               Error.new("Expected a float, received: 123.", [])
             ]

      assert validate(1.44, float()) == []
    end

    test "req_float/1 expects a float value" do
      assert validate("hello", req_float()) == [
               Error.new("Expected a float, received: \"hello\".", [])
             ]

      assert validate(123, req_float()) == [
               Error.new("Expected a float, received: 123.", [])
             ]

      assert validate(1.44, req_float()) == []
    end

    test "integer/1 expects an integer value" do
      assert validate("hello", integer()) == [
               Error.new("Expected an integer, received: \"hello\".", [])
             ]

      assert validate(1.44, integer()) == [
               Error.new("Expected an integer, received: 1.44.", [])
             ]

      assert validate(123, integer()) == []
    end

    test "req_integer/1 expects an integer value" do
      assert validate("hello", req_integer()) == [
               Error.new("Expected an integer, received: \"hello\".", [])
             ]

      assert validate(1.44, req_integer()) == [
               Error.new("Expected an integer, received: 1.44.", [])
             ]

      assert validate(123, req_integer()) == []
    end

    test "string/1 expects a string value" do
      assert validate(123, string()) == [Error.new("Expected a string, received: 123.", [])]
      assert validate(true, string()) == [Error.new("Expected a string, received: true.", [])]
      assert validate("hello", string()) == []
    end

    test "req_string/1 expects a string value" do
      assert validate(123, req_string()) == [Error.new("Expected a string, received: 123.", [])]
      assert validate(true, req_string()) == [Error.new("Expected a string, received: true.", [])]
      assert validate("hello", req_string()) == []
    end
  end

  describe "checks" do
    import Validator.Helpers
    import Validator.Rule

    test "are evaluated for basic values" do
      checks = [one_of([0, 1])]
      expected_errors = [Error.new("Invalid value '123'. Valid options: [0, 1]", [])]

      assert validate(123, value(checks: checks)) == expected_errors
      assert validate(123, number(checks: checks)) == expected_errors
      assert validate(123, integer(checks: checks)) == expected_errors
      assert validate(0, integer(checks: checks)) == []
    end

    test "are all evaluated" do
      checks = [rule(&(&1 < 100), "bigger than 100"), rule(&(&1 < 1000), "bigger than 1000")]

      assert validate(1001, integer(checks: checks)) == [
               Error.new("bigger than 100", []),
               Error.new("bigger than 1000", [])
             ]

      assert validate(101, integer(checks: checks)) == [Error.new("bigger than 100", [])]
      assert validate(11, integer(checks: checks)) == []
    end
  end

  describe "lists" do
    import Validator.Helpers
    import Validator.Rule

    test "evaluate all their elements" do
      assert validate([1, 2, 3, "4", "5", 6], list(integer())) == [
               Error.new("Expected an integer, received: \"4\".", [3]),
               Error.new("Expected an integer, received: \"5\".", [4])
             ]
    end

    test "accepts [item_type] as a shortcut" do
      assert validate([1, 2, 3, "4", "5", 6], [integer()]) == [
               Error.new("Expected an integer, received: \"4\".", [3]),
               Error.new("Expected an integer, received: \"5\".", [4])
             ]
    end

    test "accept checks at the item and the list level" do
      item_checks = [rule(&(&1 < 5), "must be lower than 5")]
      list_checks = [rule(&(length(&1) < 4), "must have less than 4 elements")]

      assert validate([1, 2, 3, 4, 5], list(integer(checks: item_checks), checks: list_checks)) ==
               [
                 Error.new("must have less than 4 elements", []),
                 Error.new("must be lower than 5", [4])
               ]
    end

    test "return an error when value is not a list" do
      assert validate(nil, list(string())) == [Error.new("Expected a list, got: nil", [])]
      assert validate(999, list(string())) == [Error.new("Expected a list, got: 999", [])]
    end
  end

  describe "maps" do
    import Validator.Helpers
    import Validator.Rule

    test "detect missing required fields" do
      schema = %{
        "name" => req_string(),
        "age" => req_number(),
        "address" => string(),
        "score" => req_number(),
        "valid" => req_boolean()
      }

      value = %{
        "name" => "Steve",
        "score" => 28
      }

      assert validate(value, schema) == [
               Error.new(~s(Missing required fields: ["age", "valid"]), [])
             ]
    end

    test "detect unexpected fields" do
      schema = %{
        "x" => req_number(),
        "y" => req_number()
      }

      value = %{
        "name" => "secret_location",
        "x" => 17,
        "y" => 14,
        "z" => 15
      }

      assert validate(value, schema) == [
               Error.new(~s(Unexpected fields: ["name", "z"]), [])
             ]
    end

    test "accept checks at the map and the field level" do
      map_checks = [rule(&(&1["x"] < &1["y"]), "x must be lower than y")]
      field_checks = [rule(&(&1 > 0), "must be positive")]

      schema =
        map(
          %{
            "x" => req_number(checks: field_checks),
            "y" => req_number(checks: field_checks)
          },
          checks: map_checks
        )

      value = %{
        "x" => 18,
        "y" => -5
      }

      assert validate(value, schema) == [
               Error.new("x must be lower than y", []),
               Error.new("must be positive", ["y"])
             ]
    end

    test "return an error when value is not a map" do
      assert validate(nil, %{}) == [Error.new("Expected a map, got: nil", [])]
      assert validate(999, %{}) == [Error.new("Expected a map, got: 999", [])]
    end
  end

  describe "defvalidator macro" do
    test "can be used to avoid importing globally all the helpers" do
      schema =
        defvalidator do
          %{
            "name" => req_string(checks: [rule(&(&1 != ""), "is empty")]),
            "gender" => req_string(checks: [one_of(["male", "female", "other"])])
          }
        end

      value = %{"name" => "", "gender" => "male"}

      assert validate(value, schema) == [Error.new("is empty", ["name"])]
    end
  end

  describe "complex schemas" do
    import Validator.Helpers
    import Validator.Rule

    test "it validates map and list fields" do
      schema = %{
        "config" =>
          req_map(%{
            "min" => req_number(),
            "max" => number()
          }),
        "config_override" => %{},
        "products" =>
          req_list(%{
            "product_id" => req_string(),
            "price" => req_number()
          }),
        "related_ids" => [string()]
      }

      assert validate(%{}, schema) == [
               Error.new("Missing required fields: [\"config\", \"products\"]", [])
             ]

      assert validate(%{"config" => %{}, "products" => [100]}, schema) == [
               Error.new("Missing required fields: [\"min\"]", ["config"]),
               Error.new("Expected a map, got: 100", ["products", 0])
             ]
    end

    test "it can validate lists of lists" do
      schema = [[[string()]]]

      assert validate(["hey"], schema) == [Error.new("Expected a list, got: \"hey\"", [0])]
      assert validate([["hey"]], schema) == [Error.new("Expected a list, got: \"hey\"", [0, 0])]
      assert validate([[["hey"]]], schema) == []
      assert validate([[["hey"], []], []], schema) == []

      assert validate([[[14]]], schema) == [
               Error.new("Expected a string, received: 14.", [0, 0, 0])
             ]
    end

    defp required_if_is_key() do
      Validator.Rule.rule(
        fn field -> not (field["is_key"] == true and not field["is_required"]) end,
        fn field -> "Field '#{field["name"]}' is a key but is not required" end
      )
    end

    test "it validates very complex schema" do
      schema = %{
            "format" => req_string(checks: [one_of(["csv", "xml"])]),
            "regex" => req_string(),
            "bim" => %{
              "truc" => req_string()
            },
            "polling" =>
              map(%{
                "slice_size" =>
                  value(
                    checks: [
                      rule(&(String.length(&1) > 100), "Slice size must be longer than 100")
                    ]
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
                checks: [rule(&(length(&1) > 0), "Fields must contain at least one item")]
              ),
            "brands" => [string()]
          }

      value = %{
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

      assert Validator.validate(value, schema) == [
        Error.new("Unexpected fields: [\"file_max_age_days\", \"options\"]", []),
        Error.new("Missing required fields: [\"truc\"]", ["bim"]),
        Error.new("Expected a string, received: 28.", ["brands", 1]),
        Error.new("Field 'a' is a key but is not required", ["fields", 0]),
        Error.new("Unexpected fields: [\"tru\"]", ["fields", 1]),
        Error.new("Missing required fields: [\"id\"]", ["fields", 1, "meta"]),
        Error.new("Invalid value 'yml'. Valid options: [\"csv\", \"xml\"]", ["format"]),
        Error.new("Unexpected fields: [\"interval_seconds\", \"timeout_ms\"]", ["polling"]),
        Error.new("Slice size must be longer than 100", ["polling", "slice_size"])
      ]
    end
  end
end
