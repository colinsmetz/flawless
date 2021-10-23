defmodule FlawlessTest do
  use ExUnit.Case, async: true
  doctest Flawless
  import Flawless, only: [validate: 2, validate: 3]
  alias Flawless.Error

  describe "basic types" do
    import Flawless.Helpers

    test "any/1 expects any value" do
      assert validate(123, any()) == []
      assert validate(true, any()) == []
      assert validate("hey", any()) == []
    end

    test "boolean/1 expects a boolean value" do
      assert validate(123, boolean()) == [Error.new("Expected type: boolean, got: 123.", [])]
      assert validate(true, boolean()) == []
      assert validate(false, boolean()) == []
    end

    test "number/1 expects a number value" do
      assert validate("hello", number()) == [
               Error.new("Expected type: number, got: \"hello\".", [])
             ]

      assert validate(123, number()) == []
      assert validate(1.44, number()) == []
    end

    test "float/1 expects a float value" do
      assert validate("hello", float()) == [
               Error.new("Expected type: float, got: \"hello\".", [])
             ]

      assert validate(123, float()) == [
               Error.new("Expected type: float, got: 123.", [])
             ]

      assert validate(1.44, float()) == []
    end

    test "integer/1 expects an integer value" do
      assert validate("hello", integer()) == [
               Error.new("Expected type: integer, got: \"hello\".", [])
             ]

      assert validate(1.44, integer()) == [
               Error.new("Expected type: integer, got: 1.44.", [])
             ]

      assert validate(123, integer()) == []
    end

    test "string/1 expects a string value" do
      assert validate(123, string()) == [Error.new("Expected type: string, got: 123.", [])]
      assert validate(true, string()) == [Error.new("Expected type: string, got: true.", [])]
      assert validate("hello", string()) == []
    end

    test "atom/1 expects an atom value" do
      assert validate(123, atom()) == [Error.new("Expected type: atom, got: 123.", [])]

      assert validate("hello", atom()) == [
               Error.new("Expected type: atom, got: \"hello\".", [])
             ]

      assert validate(:test, atom()) == []
    end

    test "pid/1 expects a pid value" do
      assert validate(:c.pid(0, 1, 2), pid()) == []
      assert validate(self(), pid()) == []
      assert validate("self", pid()) == [Error.new("Expected type: pid, got: \"self\".", [])]
      assert validate(123, pid()) == [Error.new("Expected type: pid, got: 123.", [])]
    end

    test "ref/1 expects a ref value" do
      assert validate(make_ref(), ref()) == []
      assert validate("self", ref()) == [Error.new("Expected type: ref, got: \"self\".", [])]
      assert validate(123, ref()) == [Error.new("Expected type: ref, got: 123.", [])]
    end

    test "function/1 expects a function value" do
      assert validate(fn -> 1 end, function()) == []
      assert validate(&(&1 + &2), function()) == []

      assert validate("fn", function()) == [
               Error.new("Expected type: function, got: \"fn\".", [])
             ]

      assert validate(123, function()) == [Error.new("Expected type: function, got: 123.", [])]
    end

    test "port/1 expects a port value" do
      assert validate(Port.list() |> Enum.at(0), port()) == []
      assert validate("self", port()) == [Error.new("Expected type: port, got: \"self\".", [])]
      assert validate(123, port()) == [Error.new("Expected type: port, got: 123.", [])]
    end

    test "number/1 and integer/1 have shortcut rules" do
      for rule_func <- [&number/1, &integer/1] do
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

    test "float/1 has shortcut rules" do
      assert validate(0.0, float(min: 2.0, max: 10.0)) == [
               Error.new("Must be greater than or equal to 2.0.", [])
             ]

      assert validate(100.0, float(min: 2.0, max: 10.0)) == [
               Error.new("Must be less than or equal to 10.0.", [])
             ]

      assert validate(2.0, float(in: [1.0, 3.0, 5.0])) == [
               Error.new("Invalid value: 2.0. Valid options: [1.0, 3.0, 5.0]", [])
             ]

      assert validate(7.0, float(between: [1.0, 5.0])) == [
               Error.new("Must be between 1.0 and 5.0.", [])
             ]
    end

    test "string/1 has shortcut rules" do
      assert validate("hey", string(min_length: 5)) == [
               Error.new("Minimum length of 5 required (current: 3).", [])
             ]

      assert validate("validation", string(max_length: 5)) == [
               Error.new("Maximum length of 5 required (current: 10).", [])
             ]

      assert validate("hey", string(length: 5)) == [
               Error.new("Expected length of 5 (current: 3).", [])
             ]

      assert validate("", string(non_empty: true, in: ["plop"], format: ~r/plop/)) == [
               Error.new(
                 [
                   "Invalid value: \"\". Valid options: [\"plop\"]",
                   "Value cannot be empty.",
                   "Value \"\" does not match regex ~r/plop/."
                 ],
                 []
               )
             ]
    end

    test "boolean/1 has shortcut rules" do
      assert validate(true, boolean(in: [false])) == [
               Error.new("Invalid value: true. Valid options: [false]", [])
             ]
    end

    test "atom/1 has shortcut rules" do
      assert validate(:hola, atom(in: [:abc, :def])) == [
               Error.new("Invalid value: :hola. Valid options: [:abc, :def]", [])
             ]
    end

    test "function/1 has shortcut rules" do
      assert validate(&Enum.count/1, function(in: [&Enum.sum/1, &List.first/1])) == [
               Error.new(
                 "Invalid value: &Enum.count/1. Valid options: [&Enum.sum/1, &List.first/1]",
                 []
               )
             ]

      assert validate(fn -> 0 end, function(arity: 1)) == [
               Error.new("Expected arity of 1, found: 0.", [])
             ]
    end
  end

  describe "checks" do
    import Flawless.Helpers
    import Flawless.Rule

    test "are evaluated for basic values" do
      checks = [one_of([0, 1])]
      expected_errors = [Error.new("Invalid value: 123. Valid options: [0, 1]", [])]

      assert validate(123, any(checks: checks)) == expected_errors
      assert validate(123, number(checks: checks)) == expected_errors
      assert validate(123, integer(checks: checks)) == expected_errors
      assert validate(0, integer(checks: checks)) == []
    end

    test "are all evaluated" do
      checks = [rule(&(&1 < 100), "bigger than 100"), rule(&(&1 < 1000), "bigger than 1000")]

      assert validate(1001, integer(checks: checks)) == [
               Error.new(["bigger than 100", "bigger than 1000"], [])
             ]

      assert validate(101, integer(checks: checks)) == [Error.new("bigger than 100", [])]
      assert validate(11, integer(checks: checks)) == []
    end

    test "can be set with :checks or multiple :check" do
      assert validate(0, integer(checks: [min(10), min(100)], check: min(25), check: min(17))) ==
               [
                 Error.new(
                   [
                     "Must be greater than or equal to 10.",
                     "Must be greater than or equal to 100.",
                     "Must be greater than or equal to 25.",
                     "Must be greater than or equal to 17."
                   ],
                   []
                 )
               ]
    end

    test "are not evaluated if the type is invalid" do
      assert validate(14, string(checks: [min_length(10), one_of(["a", "b"])])) == [
               Error.new("Expected type: string, got: 14.", [])
             ]

      assert validate("xx", number(checks: [min(10)], cast_from: :string)) == [
               Error.new("Cannot be cast to number.", [])
             ]
    end

    test "accepts basic functions as rules" do
      assert validate(100, number(check: &(&1 > 0))) == []
      assert validate(-4, number(check: &(&1 > 0))) == [Error.new("The predicate failed.", [])]
    end
  end

  describe "late checks" do
    import Flawless.Helpers
    import Flawless.Rule

    test "are not evaluated if other checks failed" do
      assert validate("ho", string(min_length: 3, late_checks: [one_of(["plop"])])) == [
               Error.new("Minimum length of 3 required (current: 2).", [])
             ]

      assert validate(
               %{"a" => 18, "b" => "19"},
               map(
                 %{"a" => string(), "b" => string()},
                 late_checks: [rule(&(&1["a"] == &1["b"]), "a must be equal to b")]
               )
             ) == [Error.new("Expected type: string, got: 18.", ["a"])]
    end

    test "are evaluated if the value is otherwise valid" do
      assert validate("hoot", string(min_length: 3, late_checks: [one_of(["plop"])])) == [
               Error.new("Invalid value: \"hoot\". Valid options: [\"plop\"]", [])
             ]

      assert validate(
               %{"a" => "y", "b" => "x"},
               map(
                 %{"a" => string(), "b" => string()},
                 late_checks: [rule(&(&1["a"] == &1["b"]), "a must be equal to b")]
               )
             ) == [Error.new("a must be equal to b", [])]
    end

    test "can be set with :late_checks or multiple :late_check" do
      assert validate(
               0,
               integer(
                 late_checks: [min(10), min(100)],
                 late_check: min(25),
                 late_check: min(17)
               ),
               group_errors: false
             ) ==
               [
                 Error.new("Must be greater than or equal to 10.", []),
                 Error.new("Must be greater than or equal to 100.", []),
                 Error.new("Must be greater than or equal to 25.", []),
                 Error.new("Must be greater than or equal to 17.", [])
               ]
    end
  end

  describe "lists" do
    import Flawless.Helpers
    import Flawless.Rule

    test "evaluate all their elements" do
      assert validate([1, 2, 3, "4", "5", 6], list(integer())) == [
               Error.new("Expected type: integer, got: \"4\".", [3]),
               Error.new("Expected type: integer, got: \"5\".", [4])
             ]
    end

    test "accepts [item_type] as a shortcut" do
      assert validate([1, 2, 3, "4", "5", 6], [integer()]) == [
               Error.new("Expected type: integer, got: \"4\".", [3]),
               Error.new("Expected type: integer, got: \"5\".", [4])
             ]
    end

    test "accepts [] to match any list" do
      assert validate([], []) == []
      assert validate([1, "hey", true], []) == []
      assert validate(17, []) == [Error.new("Expected type: list, got: 17.", [])]
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
      assert validate(nil, list(string())) == [Error.new("Expected type: list, got: nil.", [])]
      assert validate(999, list(string())) == [Error.new("Expected type: list, got: 999.", [])]
    end

    test "have shortcut rules" do
      assert validate([1, 2, 3], list(number(), min_length: 5)) == [
               Error.new("Minimum length of 5 required (current: 3).", [])
             ]

      assert validate([1, 2, 3, 4], list(number(), max_length: 3)) == [
               Error.new("Maximum length of 3 required (current: 4).", [])
             ]

      assert validate([1, 2, 3], list(number(), length: 5)) == [
               Error.new("Expected length of 5 (current: 3).", [])
             ]

      assert validate([], list(number(), non_empty: true, in: [[1, 2]])) == [
               Error.new(
                 [
                   "Invalid value: []. Valid options: [[1, 2]]",
                   "Value cannot be empty."
                 ],
                 []
               )
             ]

      assert validate([1, 1, 2], list(number(), no_duplicate: true)) == [
               Error.new("The list should not contain duplicates (duplicates found: [1]).", [])
             ]
    end
  end

  describe "maps" do
    import Flawless.Helpers
    import Flawless.Rule

    test "detect missing required fields" do
      schema = %{
        "name" => string(),
        "age" => number(),
        "score" => number(),
        "valid" => boolean(),
        "something" => fn
          %{} -> %{"a" => string()}
          {_} -> {string()}
        end,
        maybe("address") => string()
      }

      value = %{
        "name" => "Steve",
        "score" => 28
      }

      assert validate(value, schema) == [
               Error.new(
                 ~s/Missing required fields: "age" (number), "something", "valid" (boolean)./,
                 []
               )
             ]
    end

    test "detect unexpected fields" do
      schema = %{
        "x" => number(),
        "y" => number()
      }

      value = %{
        "name" => "secret_location",
        "x" => 17,
        "y" => 14,
        "z" => 15
      }

      assert validate(value, schema) == [
               Error.new(~s(Unexpected fields: ["name", "z"].), [])
             ]
    end

    test "accept checks at the map and the field level" do
      map_checks = [rule(&(&1["x"] < &1["y"]), "x must be lower than y")]
      field_checks = [rule(&(&1 > 0), "must be positive")]

      schema =
        map(
          %{
            "x" => number(checks: field_checks),
            "y" => number(checks: field_checks)
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
      assert validate(nil, %{}) == [Error.new("Expected type: map, got: nil.", [])]
      assert validate(999, %{}) == [Error.new("Expected type: map, got: 999.", [])]
    end

    test "have shortcut rules" do
      assert validate(%{}, map(%{}, in: [%{c: 3}])) == [
               Error.new("Invalid value: %{}. Valid options: [%{c: 3}]", [])
             ]
    end

    defmodule TestModule do
      defstruct a: nil, b: nil
    end

    test "cannot validate structs" do
      schema = %{
        a: number(),
        b: number()
      }

      assert validate(%TestModule{a: 1, b: 2}, schema) == [
               Error.new("Expected type: map, got: struct.", [])
             ]
    end

    test "accepts and validates any non-specified key with any_key()" do
      schema = %{
        "a" => string(),
        "b" => string(),
        any_key() => number()
      }

      assert validate(%{"a" => "x", "b" => "y"}, schema) == []
      assert validate(%{"a" => "x", "b" => "y", "c" => 17}, schema) == []
      assert validate(%{"a" => "x", "b" => "y", "c" => 17, "d" => 100}, schema) == []

      assert validate(%{"a" => "x", "b" => "y", "c" => 17, "d" => "hey"}, schema) == [
               Error.new("Expected type: number, got: \"hey\".", ["d"])
             ]

      assert validate(%{}, %{any_key() => any()}) == []
    end
  end

  describe "structs" do
    import Flawless.Helpers
    import Flawless.Rule

    defmodule TestStructA do
      defstruct a: nil, b: nil
    end

    defmodule TestStructB do
      defstruct a: nil, b: nil
    end

    test "accept checks at the struct and the field level" do
      map_checks = [rule(&(&1.a < &1.b), "a must be lower than b")]
      field_checks = [rule(&(&1 > 0), "must be positive")]

      schema =
        structure(
          %TestStructA{
            a: number(checks: field_checks),
            b: number(checks: field_checks)
          },
          checks: map_checks
        )

      value = %TestStructA{
        a: 18,
        b: -5
      }

      assert validate(value, schema) == [
               Error.new("a must be lower than b", []),
               Error.new("must be positive", [:b])
             ]
    end

    test "return an error when they receive a struct of another type" do
      schema = %TestStructA{
        a: number(),
        b: string()
      }

      assert validate(%TestStructB{a: 11, b: "yo"}, schema) == [
               Error.new(
                 "Expected struct of type: FlawlessTest.TestStructA, got struct of type: FlawlessTest.TestStructB.",
                 []
               )
             ]
    end

    test "return an error when value is not a struct" do
      schema = %TestStructA{
        a: number(),
        b: string()
      }

      assert validate(%{a: 11, b: "yo"}, schema) == [
               Error.new("Expected type: struct, got: %{a: 11, b: \"yo\"}.", [])
             ]

      assert validate(TestStructA, schema) == [
               Error.new("Expected type: struct, got: FlawlessTest.TestStructA.", [])
             ]
    end

    test "have shortcut rules" do
      assert validate(
               %TestStructA{},
               structure(%TestStructA{}, in: [%TestStructA{a: 3, b: 4}])
             ) == [
               Error.new(
                 "Invalid value: %FlawlessTest.TestStructA{a: nil, b: nil}. Valid options: [%FlawlessTest.TestStructA{a: 3, b: 4}]",
                 []
               )
             ]
    end

    test "can be validated based on module only for opaque structs" do
      assert validate(DateTime.utc_now(), structure(DateTime)) == []

      assert validate(1..2, structure(DateTime)) == [
               Error.new("Expected struct of type: DateTime, got struct of type: Range.", [])
             ]

      assert validate(1, structure(DateTime)) == [
               Error.new("Expected type: DateTime, got: 1.", [])
             ]
    end

    test "opaque structs still accept other options" do
      assert validate(
               1_464_096_368,
               structure(DateTime,
                 cast_from: {:integer, with: &DateTime.from_unix/1},
                 check: rule(&(&1.year == 2015), &"year should be 2015, but it is #{&1.year}")
               )
             ) == [Error.new("year should be 2015, but it is 2016", [])]
    end
  end

  describe "tuples" do
    import Flawless.Helpers
    import Flawless.Rule

    test "validate tuple size before anything else" do
      schema = tuple({number(), string(), string()})

      assert validate({1, "a", "b"}, schema) == []

      assert validate({1, 2}, schema) == [
               Error.new("Invalid tuple size (expected: 3, received: 2).", [])
             ]

      assert validate({1, 2, 3, 4}, schema) == [
               Error.new("Invalid tuple size (expected: 3, received: 4).", [])
             ]
    end

    test "detect error in tuple fields" do
      schema = tuple({number(), string(), string()})

      assert validate({1, 2, "plop"}, schema) == [
               Error.new("Expected type: string, got: 2.", [1])
             ]
    end

    test "accept direct tuple as shortcut" do
      schema = {number(), string(), string()}

      assert validate({1, 2, "plop"}, schema) == [
               Error.new("Expected type: string, got: 2.", [1])
             ]
    end

    test "accept checks at the tuple and the field level" do
      tuple_checks = [rule(&(elem(&1, 0) != elem(&1, 1)), "tuple elements must be different")]

      schema =
        tuple(
          {
            atom(checks: [one_of([:ok, :error])]),
            any()
          },
          checks: tuple_checks
        )

      assert validate({:bim, :bim}, schema) == [
               Error.new("tuple elements must be different", []),
               Error.new("Invalid value: :bim. Valid options: [:ok, :error]", [0])
             ]
    end

    test "return an error when value is not a tuple" do
      assert validate(nil, {}) == [Error.new("Expected type: tuple, got: nil.", [])]
      assert validate(999, {}) == [Error.new("Expected type: tuple, got: 999.", [])]
      assert validate([1, 2], {}) == [Error.new("Expected type: tuple, got: [1, 2].", [])]
    end

    test "have shortcut rules" do
      assert validate({}, tuple({}, in: [{1, 2}])) == [
               Error.new("Invalid value: {}. Valid options: [{1, 2}]", [])
             ]
    end
  end

  describe "literals" do
    import Flawless.Helpers
    import Flawless.Rule

    test "validate that value is strictly equal to expected value" do
      assert validate(14, literal(14)) == []
      assert validate(:plop, literal(:plop)) == []
      assert validate("abc", literal("abc")) == []
      assert validate(%{a: 1, b: []}, literal(%{a: 1, b: []})) == []

      assert validate(6, literal(10)) == [Error.new("Expected literal value 10, got: 6.", [])]
      assert validate(8, literal("8")) == [Error.new("Expected literal value \"8\", got: 8.", [])]
    end

    test "work without the `literal` helper for strings" do
      assert validate("abc", "abc") == []

      assert validate("abcd", "abc") == [
               Error.new("Expected literal value \"abc\", got: \"abcd\".", [])
             ]
    end

    test "work without the `literal` helper for atoms" do
      assert validate(:plop, :plop) == []
      assert validate(true, true) == []
      assert validate(nil, nil) == []
      assert validate(:tru, :plop) == [Error.new("Expected literal value :plop, got: :tru.", [])]
    end

    test "work without the `literal` helper for numbers" do
      assert validate(14, 14) == []
      assert validate(1.4, 1.4) == []
      assert validate(14, 100) == [Error.new("Expected literal value 100, got: 14.", [])]
    end
  end

  describe "cast_from" do
    import Flawless.Helpers
    import Flawless.Rule

    test "can be used to cast strings to numbers" do
      schema = number(cast_from: :string)

      assert validate("100", schema) == []
      assert validate("9.99", schema) == []
      assert validate(15, schema) == []
      assert validate("xxx", schema) == [Error.new("Cannot be cast to number.", [])]
      assert validate(true, schema) == [Error.new("Expected type: number, got: true.", [])]
    end

    test "can be used to cast lists to tuples" do
      schema = tuple({number(), string()}, cast_from: :list)

      assert validate([2, "euros"], schema) == []
      assert validate({2, "euros"}, schema) == []

      assert validate([2, "euros", "ttc"], schema) == [
               Error.new("Invalid tuple size (expected: 2, received: 3).", [])
             ]

      assert validate("[]", schema) == [Error.new("Expected type: tuple, got: \"[]\".", [])]
    end

    defmodule CastFromTestStruct do
      defstruct a: nil, b: nil
    end

    test "can be used to cast structs to maps" do
      schema = map(%{a: number(), b: number()}, cast_from: :struct)

      assert validate(%CastFromTestStruct{a: 1, b: 2}, schema) == []

      assert validate(%CastFromTestStruct{a: "x", b: 2}, schema) == [
               Error.new("Expected type: number, got: \"x\".", [:a])
             ]
    end

    test "accepts a list of possible types" do
      schema = string(cast_from: [:number, :boolean, :atom])

      assert validate("word", schema) == []
      assert validate(178, schema) == []
      assert validate(true, schema) == []
      assert validate(:boom, schema) == []

      assert validate(["list"], schema) == [
               Error.new("Expected type: string, got: [\"list\"].", [])
             ]
    end

    test "casts the value, then runs the checks on the converted value" do
      schema = number(cast_from: :string, checks: [max(10)])

      assert validate("-5", schema) == []
      assert validate("10", schema) == []
      assert validate("15", schema) == [Error.new("Must be less than or equal to 10.", [])]
    end

    test "cast literals" do
      schema = literal(100, cast_from: :string)

      assert validate("100", schema) == []
      assert validate("101", schema) == [Error.new("Expected literal value 100, got: 101.", [])]
    end

    test "can be used with custom converter" do
      from_hexadecimal = fn hexa ->
        case Integer.parse(hexa, 16) do
          {val, _} -> {:ok, val}
          :error -> :error
        end
      end

      schema = number(cast_from: {:string, with: from_hexadecimal})

      assert validate(10, schema) == []
      assert validate("6A23D", schema) == []
      assert validate("hey", schema) == [Error.new("Cannot be cast to number.", [])]
    end
  end

  describe "nullable option" do
    import Flawless.Helpers
    import Flawless.Rule

    test "a nil value is never accepted when nil is false, even it matches the type" do
      assert validate(nil, literal(nil, nil: false)) == [Error.new("Value cannot be nil.", [])]
      assert validate(nil, string(nil: false)) == [Error.new("Value cannot be nil.", [])]
      assert validate(nil, atom(nil: false)) == [Error.new("Value cannot be nil.", [])]

      assert validate(nil, any(in: [nil], nil: false)) == [
               Error.new("Value cannot be nil.", [])
             ]

      assert validate(nil, map(%{}, nil: false)) == [Error.new("Value cannot be nil.", [])]

      assert validate(%{"a" => nil, "b" => nil}, %{
               "a" => atom(nil: false),
               maybe("b") => string(nil: false)
             }) == [
               Error.new("Value cannot be nil.", ["a"]),
               Error.new("Value cannot be nil.", ["b"])
             ]

      assert validate(nil, tuple({atom()}, nil: false)) == [Error.new("Value cannot be nil.", [])]
    end

    test "a nil value is always accepted when nil is true, whatever the type" do
      assert validate(nil, literal(15, nil: true)) == []
      assert validate(nil, string(nil: true)) == []
      assert validate(nil, atom(nil: true)) == []
      assert validate(nil, tuple({string(), string()}, nil: true)) == []
      assert validate(%{"a" => nil}, %{"a" => port(nil: true)}) == []
    end

    test "a nil value is accepted if it matches the type and the option was not specified" do
      assert validate(nil, nil) == []
      assert validate(nil, literal(nil)) == []
      assert validate(nil, atom()) == []
      assert validate(nil, any()) == []
    end

    test "a nil value is not accepted for required fields in a map, when nothing was specified" do
      assert validate(%{"a" => nil}, %{"a" => string()}) == [
               Error.new("Expected type: string, got: nil.", ["a"])
             ]
    end

    test "a nil value is accepted for optional fields in a map, when nothing was specified" do
      assert validate(%{"a" => nil}, %{maybe("a") => string()}) == []
      assert validate(%{"a" => nil}, %{any_key() => string()}) == []
    end
  end

  describe "complex schemas" do
    import Flawless.Helpers
    import Flawless.Rule

    test "it validates map, list and tuple fields" do
      schema = %{
        "config" =>
          map(%{
            "min" => number(),
            maybe("max") => number()
          }),
        maybe("config_override") => %{},
        "products" =>
          list(%{
            "product_id" => string(),
            "price" => number()
          }),
        maybe("related_ids") => [string()],
        "coordinates" => tuple({float(), float(), float()}),
        maybe("status") => {atom(), number()}
      }

      assert validate(%{}, schema) == [
               Error.new(
                 "Missing required fields: \"config\" (map), \"coordinates\" (tuple), \"products\" (list).",
                 []
               )
             ]

      assert validate(
               %{"config" => %{}, "products" => [100], "coordinates" => {1.0, 2.0}},
               schema
             ) == [
               Error.new("Missing required fields: \"min\" (number).", ["config"]),
               Error.new("Invalid tuple size (expected: 3, received: 2).", ["coordinates"]),
               Error.new("Expected type: map, got: 100.", ["products", 0])
             ]
    end

    test "it can validate lists of lists" do
      schema = [[[string()]]]

      assert validate(["hey"], schema) == [Error.new("Expected type: list, got: \"hey\".", [0])]

      assert validate([["hey"]], schema) == [
               Error.new("Expected type: list, got: \"hey\".", [0, 0])
             ]

      assert validate([[["hey"]]], schema) == []
      assert validate([[["hey"], []], []], schema) == []

      assert validate([[[14]]], schema) == [
               Error.new("Expected type: string, got: 14.", [0, 0, 0])
             ]
    end

    test "it can validate tuples of tuples" do
      schema = {{atom(), string()}, {atom(), number(), {number()}}}

      assert validate({1, 2}, schema) == [
               Error.new("Expected type: tuple, got: 1.", [0]),
               Error.new("Expected type: tuple, got: 2.", [1])
             ]

      assert validate({{:ok, "elixir"}, {:plop, 1, 7}}, schema) == [
               Error.new("Expected type: tuple, got: 7.", [1, 2])
             ]

      assert validate({{:ok, "elixir"}, {:plop, 1, {9}}}, schema) == []
    end

    defp required_if_is_key() do
      Flawless.Rule.rule(
        fn field -> not (field["is_key"] == true and not field["is_required"]) end,
        fn field -> "Field '#{field["name"]}' is a key but is not required" end
      )
    end

    defmodule M do
      defstruct x: nil
    end

    test "it validates very complex schema" do
      schema = %{
        "format" => string(checks: [one_of(["csv", "xml"])]),
        "string" => string(),
        maybe("bim") => %{
          "truc" => string(),
          "struct" => structure(%M{x: number()})
        },
        maybe("settings") =>
          map(%{
            maybe("stuff") =>
              any(
                checks: [
                  rule(&(String.length(&1) > 100), "Stuff must be longer than 100")
                ]
              )
          }),
        "fields" =>
          list(
            map(
              %{
                "name" => string(),
                "type" => string(),
                maybe("is_key") => boolean(),
                maybe("is_required") => boolean(),
                maybe("meta") =>
                  map(%{
                    "id" => any()
                  })
              },
              checks: [required_if_is_key()]
            ),
            checks: [rule(&(length(&1) > 0), "Fields must contain at least one item")]
          ),
        maybe("brands") => [string()],
        "status" => atom(checks: [one_of([:ok, :error])]),
        "tuple_of_things" => {
          [string()],
          %{maybe("a") => string()}
        },
        maybe("test") => string(nil: false)
      }

      value = %{
        "format" => "yml",
        "string" => "/the/string",
        "options" => %{"a" => "b"},
        "bim" => %{},
        "fields" => [
          %{"name" => "a", "type" => "INT64", "is_key" => true, "is_required" => false},
          %{"name" => "b", "type" => "STRING", "tru" => "blop", "meta" => %{}}
        ],
        "settings" => %{
          "stuff" => "abcd",
          "other_stuff" => "12",
          "something" => "34567"
        },
        "unexpected_number" => "67",
        "brands" => ["hey", 28],
        "status" => :ok,
        "tuple_of_things" => {["x", "y", 9, "z"], %{}},
        "test" => nil
      }

      assert Flawless.validate(value, schema) == [
               Error.new("Unexpected fields: [\"options\", \"unexpected_number\"].", []),
               Error.new("Missing required fields: \"struct\" (struct), \"truc\" (string).", [
                 "bim"
               ]),
               Error.new("Expected type: string, got: 28.", ["brands", 1]),
               Error.new("Field 'a' is a key but is not required", ["fields", 0]),
               Error.new("Unexpected fields: [\"tru\"].", ["fields", 1]),
               Error.new("Missing required fields: \"id\" (any).", ["fields", 1, "meta"]),
               Error.new("Invalid value: \"yml\". Valid options: [\"csv\", \"xml\"]", ["format"]),
               Error.new("Unexpected fields: [\"other_stuff\", \"something\"].", ["settings"]),
               Error.new("Stuff must be longer than 100", ["settings", "stuff"]),
               Error.new("Value cannot be nil.", ["test"]),
               Error.new("Expected type: string, got: 9.", ["tuple_of_things", 0, 2])
             ]
    end
  end

  describe "recursive data structures" do
    import Flawless.Helpers
    import Flawless.Rule

    def tree_schema() do
      %{
        :value => number(max: 100),
        maybe(:left) => &tree_schema/0,
        maybe(:right) => &tree_schema/0
      }
    end

    test "are validated recursively" do
      tree = %{
        value: 17,
        left: %{
          value: 33
        },
        right: %{
          value: 18,
          left: %{
            value: 333
          }
        }
      }

      assert validate(tree, tree_schema()) == [
               Error.new("Must be less than or equal to 100.", [:right, :left, :value])
             ]

      tree2 = %{
        value: 17,
        left: %{
          value: 33
        },
        right: %{
          value: 18,
          left: %{
            value: 33
          }
        }
      }

      assert validate(tree2, tree_schema()) == []
    end
  end

  describe "selects" do
    import Flawless.Helpers
    import Flawless.Rule

    test "pass if the selected match is valid" do
      schema = %{
        a: fn
          %{} -> %{b: number(), c: number()}
          [_ | _] -> list(number())
        end
      }

      assert validate(%{a: %{b: 1, c: 2}}, schema) == []
      assert validate(%{a: [1, 2, 3]}, schema) == []
    end

    test "fail with the correct errors if select match is invalid" do
      schema = %{
        a: fn
          %{} -> %{:b => number(), maybe(:c) => number()}
          [_ | _] -> list(number())
        end
      }

      assert validate(%{a: %{c: "d"}}, schema) == [
               Error.new("Missing required fields: :b (number).", [:a]),
               Error.new("Expected type: number, got: \"d\".", [:a, :c])
             ]

      assert validate(%{a: ["1", "2"]}, schema) == [
               Error.new("Expected type: number, got: \"1\".", [:a, 0]),
               Error.new("Expected type: number, got: \"2\".", [:a, 1])
             ]
    end

    test "fail with the correct error if nothing matched in the function" do
      schema = %{
        a: fn
          %{} -> %{:b => number(), maybe(:c) => number()}
          [_ | _] -> list(number())
        end
      }

      assert validate(%{a: 14}, schema) == [
               Error.new("Value does not match any of the possible schemas.", [:a])
             ]
    end
  end

  describe "options" do
    import Flawless.Helpers
    import Flawless.Rule

    test "group_errors groups errors for the same path" do
      schema = %{
        "my" => %{
          "path" => string(min_length: 3, in: ["words"]),
          "other_path" => number(min: 2)
        }
      }

      value = %{
        "my" => %{
          "path" => "hi",
          "other_path" => "hello"
        }
      }

      assert validate(value, schema) == [
               Error.new("Expected type: number, got: \"hello\".", ["my", "other_path"]),
               Error.new(
                 [
                   "Minimum length of 3 required (current: 2).",
                   "Invalid value: \"hi\". Valid options: [\"words\"]"
                 ],
                 ["my", "path"]
               )
             ]

      assert validate(value, schema, group_errors: true) == [
               Error.new("Expected type: number, got: \"hello\".", ["my", "other_path"]),
               Error.new(
                 [
                   "Minimum length of 3 required (current: 2).",
                   "Invalid value: \"hi\". Valid options: [\"words\"]"
                 ],
                 ["my", "path"]
               )
             ]

      assert validate(value, schema, group_errors: false) == [
               Error.new("Minimum length of 3 required (current: 2).", ["my", "path"]),
               Error.new("Invalid value: \"hi\". Valid options: [\"words\"]", ["my", "path"]),
               Error.new("Expected type: number, got: \"hello\".", ["my", "other_path"])
             ]
    end

    test "stop_early only returns the first errors found when it is true" do
      schema = list(string(), length: 4)
      value = [1, 2, 3]

      assert validate(value, schema, stop_early: false) == [
               Error.new("Expected length of 4 (current: 3).", []),
               Error.new("Expected type: string, got: 1.", [0]),
               Error.new("Expected type: string, got: 2.", [1]),
               Error.new("Expected type: string, got: 3.", [2])
             ]

      assert validate(value, schema, stop_early: true) == [
               Error.new("Expected length of 4 (current: 3).", [])
             ]
    end

    test "stop_early stops early on lists" do
      schema = list(string())
      value = [1, 2, 3]

      assert validate(value, schema, stop_early: false) == [
               Error.new("Expected type: string, got: 1.", [0]),
               Error.new("Expected type: string, got: 2.", [1]),
               Error.new("Expected type: string, got: 3.", [2])
             ]

      assert validate(value, schema, stop_early: true) == [
               Error.new("Expected type: string, got: 1.", [0])
             ]
    end

    test "stop_early stops early on maps" do
      schema = %{"a" => string(), "b" => string()}
      value = %{"a" => 1, "b" => 2}

      assert validate(value, schema, stop_early: false) == [
               Error.new("Expected type: string, got: 1.", ["a"]),
               Error.new("Expected type: string, got: 2.", ["b"])
             ]

      assert validate(value, schema, stop_early: true) == [
               Error.new("Expected type: string, got: 1.", ["a"])
             ]
    end

    test "stop_early stops early on tuples" do
      schema = {string(), string(), string()}
      value = {1, 2, 3}

      assert validate(value, schema, stop_early: false) == [
               Error.new("Expected type: string, got: 1.", [0]),
               Error.new("Expected type: string, got: 2.", [1]),
               Error.new("Expected type: string, got: 3.", [2])
             ]

      assert validate(value, schema, stop_early: true) == [
               Error.new("Expected type: string, got: 1.", [0])
             ]
    end
  end

  describe "on_error" do
    import Flawless.Helpers
    import Flawless.Rule

    test "groups the errors and replaces them with a single hardcoded message" do
      schema =
        tuple(
          {atom(in: [:ok, :error]), number(min: 0)},
          on_error: "An :ok/:error tuple was expected."
        )

      assert validate({:ok, 7}, schema) == []

      assert validate({:invalid, -4}, schema) == [
               Error.new("An :ok/:error tuple was expected.", [])
             ]

      assert validate("hey", schema) == [
               Error.new("An :ok/:error tuple was expected.", [])
             ]
    end

    test "it still returns errors for other elements" do
      schema = %{
        "nickname" =>
          string(
            format: ~r/^[a-z_]+$/,
            on_error: "Only lowercase letters and underscores are allowed."
          ),
        "age" => number(min: 0)
      }

      assert validate(%{"nickname" => "Thomas", "age" => -7}, schema) == [
               Error.new("Must be greater than or equal to 0.", ["age"]),
               Error.new("Only lowercase letters and underscores are allowed.", ["nickname"])
             ]
    end
  end

  describe "unions" do
    import Flawless.Helpers
    import Flawless.Rule

    test "accept any basic type in the list, otherwise returns a generic error" do
      schema = union([string(), number()])

      assert validate("hello", schema) == []
      assert validate(18, schema) == []

      assert validate(:boo, schema) == [
               Error.new(
                 "The value does not match any schema in the union. Possible types: [:string, :number].",
                 []
               )
             ]
    end

    test "if it fails but matches the primary type of a single schema in the union, it returns the errors for that schema" do
      schema = union([string(min_length: 10), number(min: 10), atom()])

      assert validate("hello", schema) == [
               Error.new("Minimum length of 10 required (current: 5).", [])
             ]

      assert validate(5, schema) == [Error.new("Must be greater than or equal to 10.", [])]
      assert validate(:ok, schema) == []

      assert validate(%{a: 1}, schema) == [
               Error.new(
                 "The value does not match any schema in the union. Possible types: [:string, :number, :atom].",
                 []
               )
             ]
    end

    test "if it matches the primary type of more than one schema, it returns a generic error" do
      schema = union([number(min: 0), float(min: 0), string(non_empty: true)])

      assert validate(-9.9, schema) == [
               Error.new(
                 "The value does not match any schema in the union. Possible types: [:number, :float, :string].",
                 []
               )
             ]

      assert validate("", schema) == [Error.new("Value cannot be empty.", [])]
    end

    test "it takes cast_from into account" do
      schema = union([number(min: 10, cast_from: :string), atom()])

      assert validate("5", schema) == [Error.new("Must be greater than or equal to 10.", [])]
    end
  end
end
