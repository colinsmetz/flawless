defmodule Validator.RuleTest do
  use ExUnit.Case, async: true
  alias Validator.Error
  import Validator.Rule

  describe "rule/2 and evaluate/3" do
    test "returns a valid rule with a simple string error" do
      test_rule =
        rule(
          fn value -> value == "ok" end,
          "the expected error"
        )

      context = ["my", "context"]

      assert evaluate(test_rule, "ok", context) == []

      assert evaluate(test_rule, "error", context) ==
               Error.new("the expected error", context)
    end

    test "returns a valid rule with a 1-arity error function" do
      test_rule =
        rule(
          fn value -> value == "ok" end,
          fn value -> "#{value} is wrong" end
        )

      context = ["my", "context"]

      assert evaluate(test_rule, "ok", context) == []

      assert evaluate(test_rule, "plop", context) ==
               Error.new("plop is wrong", context)
    end

    test "returns a valid rule with a 2-arity error function" do
      test_rule =
        rule(
          fn value -> value == "ok" end,
          fn value, context -> "#{value} is wrong in #{context}" end
        )

      context = ["my", "context"]

      assert evaluate(test_rule, "ok", context) == []

      assert evaluate(test_rule, "plop", context) ==
               Error.new("plop is wrong in mycontext", context)
    end

    test "catches exceptions and return generic error message if it happens" do
      test_rule =
        rule(
          fn value -> String.to_integer(value) > 0 end,
          "normal error message"
        )

      assert evaluate(test_rule, "10", []) == []
      assert evaluate(test_rule, "-1", []) == Error.new("normal error message", [])

      assert evaluate(test_rule, "xxx", []) ==
               Error.new(
                 "An exception was raised while evaluating a rule on that element, so it is likely incorrect.",
                 []
               )
    end

    test "can evaluate a direct predicate function, with a generic error message" do
      test_rule = fn x -> x > 0 end

      assert evaluate(test_rule, 10, []) == []
      assert evaluate(test_rule, -4, []) == Error.new("The predicate failed.", [])
    end

    test "can use :ok/:error functions as predicates" do
      predicate = fn
        x when x > 0 -> {:ok, x}
        x when x == 0 -> :error
        x when x < 0 -> {:error, "cannot be negative"}
      end

      test_rule = rule(predicate)

      assert evaluate(test_rule, 10, []) == []
      assert evaluate(test_rule, 0, []) == Error.new("The predicate failed.", [])
      assert evaluate(test_rule, -10, []) == Error.new("cannot be negative", [])

      assert evaluate(predicate, 10, []) == []
      assert evaluate(predicate, 0, []) == Error.new("The predicate failed.", [])
      assert evaluate(predicate, -10, []) == Error.new("cannot be negative", [])
    end
  end

  describe "predefined rule" do
    test "one_of/1 validates that value is in the options" do
      test_rule = one_of([1, 2, 3])
      assert evaluate(test_rule, 1, []) == []

      assert evaluate(test_rule, 7, []) ==
               Error.new(
                 {"Invalid value: %{value}. Valid options: %{options}",
                  [value: "7", options: "[1, 2, 3]"]},
                 []
               )
    end

    test "min_length/1 validates the length of a string" do
      test_rule = min_length(5)

      assert evaluate(test_rule, "hey", []) ==
               Error.new(
                 {"Minimum length of %{min_length} required (current: %{actual_length}).",
                  [min_length: 5, actual_length: 3]},
                 []
               )

      assert evaluate(test_rule, "hell", []) ==
               Error.new(
                 {"Minimum length of %{min_length} required (current: %{actual_length}).",
                  [min_length: 5, actual_length: 4]},
                 []
               )

      assert evaluate(test_rule, "hello", []) == []
    end

    test "min_length/1 validates the length of a list" do
      test_rule = min_length(5)

      assert evaluate(test_rule, [1, 2, 3], []) ==
               Error.new(
                 {"Minimum length of %{min_length} required (current: %{actual_length}).",
                  [min_length: 5, actual_length: 3]},
                 []
               )

      assert evaluate(test_rule, [1, 2, 3, 4], []) ==
               Error.new(
                 {"Minimum length of %{min_length} required (current: %{actual_length}).",
                  [min_length: 5, actual_length: 4]},
                 []
               )

      assert evaluate(test_rule, [1, 2, 3, 4, 5], []) == []
    end

    test "max_length/1 validates the length of a string" do
      test_rule = max_length(4)

      assert evaluate(test_rule, "hey", []) == []
      assert evaluate(test_rule, "hell", []) == []

      assert evaluate(test_rule, "hello", []) ==
               Error.new(
                 {"Maximum length of %{max_length} required (current: %{actual_length}).",
                  [max_length: 4, actual_length: 5]},
                 []
               )
    end

    test "max_length/1 validates the length of a list" do
      test_rule = max_length(4)

      assert evaluate(test_rule, [1, 2, 3], []) == []
      assert evaluate(test_rule, [1, 2, 3, 4], []) == []

      assert evaluate(test_rule, [1, 2, 3, 4, 5], []) ==
               Error.new(
                 {"Maximum length of %{max_length} required (current: %{actual_length}).",
                  [max_length: 4, actual_length: 5]},
                 []
               )
    end

    test "non_empty/0 validates that the string is not empty" do
      test_rule = non_empty()

      assert evaluate(test_rule, "", []) == Error.new("Value cannot be empty.", [])
      assert evaluate(test_rule, "hello", []) == []
    end

    test "non_empty/0 validates that the list is not empty" do
      test_rule = non_empty()

      assert evaluate(test_rule, [], []) == Error.new("Value cannot be empty.", [])
      assert evaluate(test_rule, [1, 2, 3], []) == []
    end

    test "exact_length/1 validates the length of a string" do
      test_rule = exact_length(4)

      assert evaluate(test_rule, "hey", []) ==
               Error.new(
                 {"Expected length of %{expected_length} (current: %{actual_length}).",
                  [expected_length: 4, actual_length: 3]},
                 []
               )

      assert evaluate(test_rule, "hell", []) == []

      assert evaluate(test_rule, "hello", []) ==
               Error.new(
                 {"Expected length of %{expected_length} (current: %{actual_length}).",
                  [expected_length: 4, actual_length: 5]},
                 []
               )
    end

    test "exact_length/1 validates the length of a list" do
      test_rule = exact_length(4)

      assert evaluate(test_rule, [1, 2, 3], []) ==
               Error.new(
                 {"Expected length of %{expected_length} (current: %{actual_length}).",
                  [expected_length: 4, actual_length: 3]},
                 []
               )

      assert evaluate(test_rule, [1, 2, 3, 4], []) == []

      assert evaluate(test_rule, [1, 2, 3, 4, 5], []) ==
               Error.new(
                 {"Expected length of %{expected_length} (current: %{actual_length}).",
                  [expected_length: 4, actual_length: 5]},
                 []
               )
    end

    test "no_duplicates/0 detects duplicates in a list" do
      assert evaluate(no_duplicate(), [1, 5, 3, 2, 7], []) == []

      assert evaluate(no_duplicate(), [1, 5, 3, 5, 7, 3, 3], []) ==
               Error.new(
                 {"The list should not contain duplicates (duplicates found: %{duplicates}).",
                  [duplicates: "[5, 3]"]},
                 []
               )
    end

    test "match/1 validates string against a regex" do
      test_rule = match(~r/^hel/)

      assert evaluate(test_rule, "hello", []) == []
      assert evaluate(test_rule, "helicopter", []) == []

      assert evaluate(test_rule, "heyy", []) ==
               Error.new(
                 {"Value %{value} does not match regex %{regex}.",
                  [value: "\"heyy\"", regex: "~r/^hel/"]},
                 []
               )
    end

    test "match/1 accepts a string for the regex" do
      test_rule = match("^hel")

      assert evaluate(test_rule, "hello", []) == []
      assert evaluate(test_rule, "helicopter", []) == []

      assert evaluate(test_rule, "heyy", []) ==
               Error.new(
                 {"Value %{value} does not match regex %{regex}.",
                  [value: "\"heyy\"", regex: "~r/^hel/"]},
                 []
               )
    end

    test "min/1 detects when value is too low" do
      test_rule = min(10)

      assert evaluate(test_rule, 15, []) == []
      assert evaluate(test_rule, 10, []) == []

      assert evaluate(test_rule, 9, []) ==
               Error.new({"Must be greater than or equal to %{min_value}.", [min_value: 10]}, [])
    end

    test "max/1 detects when value is too high" do
      test_rule = max(10)

      assert evaluate(test_rule, 5, []) == []
      assert evaluate(test_rule, 10, []) == []

      assert evaluate(test_rule, 11, []) ==
               Error.new({"Must be less than or equal to %{max_value}.", [max_value: 10]}, [])
    end

    test "between/2 detects when value is out of range" do
      test_rule = between(3, 6)

      assert evaluate(test_rule, 2, []) ==
               Error.new(
                 {"Must be between %{min_value} and %{max_value}.", [min_value: 3, max_value: 6]},
                 []
               )

      assert evaluate(test_rule, 3, []) == []
      assert evaluate(test_rule, 5, []) == []
      assert evaluate(test_rule, 6, []) == []

      assert evaluate(test_rule, 7, []) ==
               Error.new(
                 {"Must be between %{min_value} and %{max_value}.", [min_value: 3, max_value: 6]},
                 []
               )
    end

    test "not_both/2 detects when a map contains both keys" do
      test_rule = not_both("a", "b")

      assert evaluate(test_rule, %{}, []) == []
      assert evaluate(test_rule, %{"a" => 17}, []) == []
      assert evaluate(test_rule, %{"b" => 15}, []) == []

      assert evaluate(test_rule, %{"b" => 12, "a" => 9}, []) ==
               Error.new(
                 {"Fields %{field1} and %{field2} cannot both be defined.",
                  [field1: "a", field2: "b"]},
                 []
               )
    end

    test "arity/1 checks the arity of a function" do
      test_rule = arity(2)

      assert evaluate(test_rule, fn -> 0 end, []) ==
               Error.new(
                 {"Expected arity of %{expected_arity}, found: %{actual_arity}.",
                  [expected_arity: 2, actual_arity: 0]},
                 []
               )

      assert evaluate(test_rule, fn x -> x end, []) ==
               Error.new(
                 {"Expected arity of %{expected_arity}, found: %{actual_arity}.",
                  [expected_arity: 2, actual_arity: 1]},
                 []
               )

      assert evaluate(test_rule, fn x, y -> x + y end, []) == []

      assert evaluate(test_rule, fn x, y, z -> x + y + z end, []) ==
               Error.new(
                 {"Expected arity of %{expected_arity}, found: %{actual_arity}.",
                  [expected_arity: 2, actual_arity: 3]},
                 []
               )
    end
  end
end
