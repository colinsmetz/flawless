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

  defp required_if_is_key() do
    Validator.Rule.rule(
      fn field -> not (field["is_key"] == true and not field["is_required"]) end,
      fn field -> "Field '#{field["name"]}' is a key but is not required" end
    )
  end

  @tag skip: "to rewrite"
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

    schema =
      defvalidator do
        %{
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
              checks: [rule(&(length(&1) > 0), "Fields must contain at least one item")]
            ),
          "brands" => [string()]
        }
      end

    Validator.validate(map, schema) |> IO.inspect()
  end

  @tag skip: "to rewrite"
  test "it works with basic type" do
    value = "14"
    schema = defvalidator(do: integer())
    Validator.validate(value, schema) |> IO.inspect()
  end

  @tag skip: "to rewrite"
  test "it works with list type" do
    value = ["yo"]
    schema = defvalidator(do: list(integer()))
    Validator.validate(value, schema) |> IO.inspect()
  end

  @tag skip: "to rewrite"
  test "it works with list type, using shortcut" do
    value = ["yo"]
    schema = defvalidator(do: [integer()])
    Validator.validate(value, schema) |> IO.inspect()
  end

  @tag skip: "to rewrite"
  test "it detects when it is not a map" do
    value = nil
    schema = %{}
    Validator.validate(value, schema) |> IO.inspect()
  end
end
