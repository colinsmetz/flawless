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

    test "atom/1 expects an atom value" do
      assert validate(123, atom()) == [Error.new("Expected an atom, received: 123.", [])]

      assert validate("hello", atom()) == [
               Error.new("Expected an atom, received: \"hello\".", [])
             ]

      assert validate(:test, atom()) == []
    end

    test "req_atom/1 expects an atom value" do
      assert validate(123, req_atom()) == [Error.new("Expected an atom, received: 123.", [])]

      assert validate("hello", req_atom()) == [
               Error.new("Expected an atom, received: \"hello\".", [])
             ]

      assert validate(:test, req_atom()) == []
    end

    test "number/1, req_number/1, integer/1 and req_integer/1 have shortcut rules" do
      for rule_func <- [&number/1, &req_number/1, &integer/1, &req_integer/1] do
        assert validate(0, rule_func.(min: 2, max: 10)) == [
                 Error.new("Must be greater than or equal to 2.", [])
               ]

        assert validate(100, rule_func.(min: 2, max: 10)) == [
                 Error.new("Must be less than or equal to 10.", [])
               ]

        assert validate(2, rule_func.(in: [1, 3, 5])) == [
                 Error.new("Invalid value: 2. Valid options: [1, 3, 5]", [])
               ]

        assert validate(7, rule_func.(between: [1, 5])) == [
                 Error.new("Must be between 1 and 5.", [])
               ]
      end
    end

    test "float/1 and req_float/1 have shortcut rules" do
      for rule_func <- [&float/1, &req_float/1] do
        assert validate(0.0, rule_func.(min: 2.0, max: 10.0)) == [
                 Error.new("Must be greater than or equal to 2.0.", [])
               ]

        assert validate(100.0, rule_func.(min: 2.0, max: 10.0)) == [
                 Error.new("Must be less than or equal to 10.0.", [])
               ]

        assert validate(2.0, rule_func.(in: [1.0, 3.0, 5.0])) == [
                 Error.new("Invalid value: 2.0. Valid options: [1.0, 3.0, 5.0]", [])
               ]

        assert validate(7.0, rule_func.(between: [1.0, 5.0])) == [
                 Error.new("Must be between 1.0 and 5.0.", [])
               ]
      end
    end

    test "string/1 and req_string/1 have shortcut rules" do
      for rule_func <- [&string/1, &req_string/1] do
        assert validate("hey", rule_func.(min_length: 5)) == [
                 Error.new("Minimum length of 5 required (current: 3).", [])
               ]

        assert validate("validation", rule_func.(max_length: 5)) == [
                 Error.new("Maximum length of 5 required (current: 10).", [])
               ]

        assert validate("hey", rule_func.(length: 5)) == [
                 Error.new("Expected length of 5 (current: 3).", [])
               ]

        assert validate("", rule_func.(non_empty: true, in: ["plop"], format: ~r/plop/)) == [
                 Error.new("Invalid value: \"\". Valid options: [\"plop\"]", []),
                 Error.new("Value cannot be empty.", []),
                 Error.new("Value \"\" does not match regex ~r/plop/.", [])
               ]
      end
    end

    test "boolean/1 and req_boolean/1 have shortcut rules" do
      for rule_func <- [&boolean/1, &req_boolean/1] do
        assert validate(true, rule_func.(in: [false])) == [
                 Error.new("Invalid value: true. Valid options: [false]", [])
               ]
      end
    end

    test "atom/1 and req_atom/1 have shortcut rules" do
      for rule_func <- [&atom/1, &req_atom/1] do
        assert validate(:hola, rule_func.(in: [:abc, :def])) == [
                 Error.new("Invalid value: :hola. Valid options: [:abc, :def]", [])
               ]
      end
    end
  end

  describe "checks" do
    import Validator.Helpers
    import Validator.Rule

    test "are evaluated for basic values" do
      checks = [one_of([0, 1])]
      expected_errors = [Error.new("Invalid value: 123. Valid options: [0, 1]", [])]

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

    test "can be set with :checks or multiple :check" do
      assert validate(0, integer(checks: [min(10), min(100)], check: min(25), check: min(17))) ==
               [
                 Error.new("Must be greater than or equal to 10.", []),
                 Error.new("Must be greater than or equal to 100.", []),
                 Error.new("Must be greater than or equal to 25.", []),
                 Error.new("Must be greater than or equal to 17.", [])
               ]
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

    test "accepts [] to match any list" do
      assert validate([], []) == []
      assert validate([1, "hey", true], []) == []
      assert validate(17, []) == [Error.new("Expected a list, got: 17", [])]
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

    test "have shortcut rules" do
      for rule_func <- [&list/2, &req_list/2] do
        assert validate([1, 2, 3], rule_func.(number(), min_length: 5)) == [
                 Error.new("Minimum length of 5 required (current: 3).", [])
               ]

        assert validate([1, 2, 3, 4], rule_func.(number(), max_length: 3)) == [
                 Error.new("Maximum length of 3 required (current: 4).", [])
               ]

        assert validate([1, 2, 3], rule_func.(number(), length: 5)) == [
                 Error.new("Expected length of 5 (current: 3).", [])
               ]

        assert validate([], rule_func.(number(), non_empty: true, in: [[1, 2]])) == [
                 Error.new("Invalid value: []. Valid options: [[1, 2]]", []),
                 Error.new("Value cannot be empty.", [])
               ]

        assert validate([1, 1, 2], rule_func.(number(), no_duplicate: true)) == [
                 Error.new("The list should not contain duplicates (duplicates found: [1]).", [])
               ]
      end
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

    test "have shortcut rules" do
      for rule_func <- [&map/2, &req_map/2] do
        assert validate(%{}, rule_func.(%{}, in: [%{c: 3}])) == [
                 Error.new("Invalid value: %{}. Valid options: [%{c: 3}]", [])
               ]
      end
    end
  end

  describe "tuples" do
    import Validator.Helpers
    import Validator.Rule

    test "validate tuple size before anything else" do
      schema = tuple({number(), string(), string()})

      assert validate({1, "a", "b"}, schema) == []

      assert validate({1, 2}, schema) == [
               Error.new("Invalid tuple size (expected: 3, received: 2)", [])
             ]

      assert validate({1, 2, 3, 4}, schema) == [
               Error.new("Invalid tuple size (expected: 3, received: 4)", [])
             ]
    end

    test "detect error in tuple fields" do
      schema = tuple({number(), string(), string()})

      assert validate({1, 2, "plop"}, schema) == [
               Error.new("Expected a string, received: 2.", [1])
             ]
    end

    test "accept direct tuple as shortcut" do
      schema = {number(), string(), string()}

      assert validate({1, 2, "plop"}, schema) == [
               Error.new("Expected a string, received: 2.", [1])
             ]
    end

    test "accept checks at the tuple and the field level" do
      tuple_checks = [rule(&(elem(&1, 0) != elem(&1, 1)), "tuple elements must be different")]

      schema =
        tuple(
          {
            atom(checks: [one_of([:ok, :error])]),
            value()
          },
          checks: tuple_checks
        )

      assert validate({:bim, :bim}, schema) == [
               Error.new("tuple elements must be different", []),
               Error.new("Invalid value: :bim. Valid options: [:ok, :error]", [0])
             ]
    end

    test "return an error when value is not a tuple" do
      assert validate(nil, {}) == [Error.new("Expected a tuple, got: nil", [])]
      assert validate(999, {}) == [Error.new("Expected a tuple, got: 999", [])]
      assert validate([1, 2], {}) == [Error.new("Expected a tuple, got: [1, 2]", [])]
    end

    test "have shortcut rules" do
      for rule_func <- [&tuple/2, &req_tuple/2] do
        assert validate({}, rule_func.({}, in: [{1, 2}])) == [
                 Error.new("Invalid value: {}. Valid options: [{1, 2}]", [])
               ]
      end
    end
  end

  describe "cast_from" do
    import Validator.Helpers
    import Validator.Rule

    test "can be used to cast strings to numbers" do
      schema = number(cast_from: :string)

      assert validate("100", schema) == []
      assert validate("9.99", schema) == []
      assert validate(15, schema) == []
      assert validate("xxx", schema) == [Error.new("Cannot be cast to number.", [])]
      assert validate(true, schema) == [Error.new("Expected a number, received: true.", [])]
    end

    test "can be used to cast lists to tuples" do
      schema = tuple({number(), string()}, cast_from: :list)

      assert validate([2, "euros"], schema) == []
      assert validate({2, "euros"}, schema) == []

      assert validate([2, "euros", "ttc"], schema) == [
               Error.new("Invalid tuple size (expected: 2, received: 3)", [])
             ]

      assert validate("[]", schema) == [Error.new("Expected a tuple, got: \"[]\"", [])]
    end

    test "accepts a list of possible types" do
      schema = string(cast_from: [:number, :boolean, :atom])

      assert validate("word", schema) == []
      assert validate(178, schema) == []
      assert validate(true, schema) == []
      assert validate(:boom, schema) == []

      assert validate(["list"], schema) == [
               Error.new("Expected a string, received: [\"list\"].", [])
             ]
    end

    test "casts the value, then runs the checks on the converted value" do
      schema = number(cast_from: :string, checks: [max(10)])

      assert validate("-5", schema) == []
      assert validate("10", schema) == []
      assert validate("15", schema) == [Error.new("Must be less than or equal to 10.", [])]
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

    test "it validates map, list and tuple fields" do
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
        "related_ids" => [string()],
        "coordinates" => req_tuple({float(), float(), float()}),
        "status" => {atom(), number()}
      }

      assert validate(%{}, schema) == [
               Error.new(
                 "Missing required fields: [\"config\", \"coordinates\", \"products\"]",
                 []
               )
             ]

      assert validate(
               %{"config" => %{}, "products" => [100], "coordinates" => {1.0, 2.0}},
               schema
             ) == [
               Error.new("Missing required fields: [\"min\"]", ["config"]),
               Error.new("Invalid tuple size (expected: 3, received: 2)", ["coordinates"]),
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

    test "it can validate tuples of tuples" do
      schema = {{atom(), string()}, {atom(), number(), {number()}}}

      assert validate({1, 2}, schema) == [
               Error.new("Expected a tuple, got: 1", [0]),
               Error.new("Expected a tuple, got: 2", [1])
             ]

      assert validate({{:ok, "elixir"}, {:plop, 1, 7}}, schema) == [
               Error.new("Expected a tuple, got: 7", [1, 2])
             ]

      assert validate({{:ok, "elixir"}, {:plop, 1, {9}}}, schema) == []
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
        "brands" => [string()],
        "status" => req_atom(checks: [one_of([:ok, :error])]),
        "tuple_of_things" => {
          [string()],
          %{"a" => string()}
        }
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
        "brands" => ["hey", 28],
        "status" => :ok,
        "tuple_of_things" => {["x", "y", 9, "z"], %{}}
      }

      assert Validator.validate(value, schema) == [
               Error.new("Unexpected fields: [\"file_max_age_days\", \"options\"]", []),
               Error.new("Missing required fields: [\"truc\"]", ["bim"]),
               Error.new("Expected a string, received: 28.", ["brands", 1]),
               Error.new("Field 'a' is a key but is not required", ["fields", 0]),
               Error.new("Unexpected fields: [\"tru\"]", ["fields", 1]),
               Error.new("Missing required fields: [\"id\"]", ["fields", 1, "meta"]),
               Error.new("Invalid value: \"yml\". Valid options: [\"csv\", \"xml\"]", ["format"]),
               Error.new("Unexpected fields: [\"interval_seconds\", \"timeout_ms\"]", ["polling"]),
               Error.new("Slice size must be longer than 100", ["polling", "slice_size"]),
               Error.new("Expected a string, received: 9.", ["tuple_of_things", 0, 2])
             ]
    end
  end
end
