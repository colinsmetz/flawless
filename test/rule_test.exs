defmodule Validator.RuleTest do
  use ExUnit.Case, async: true
  alias Validator.Error
  import Validator.Rule

  describe "rule/2" do
    test "returns a valid rule with a simple string error" do
      test_rule =
        rule(
          fn value -> value == "ok" end,
          "the expected error"
        )

      context = ["my", "context"]

      assert test_rule.("ok", context) == []

      assert test_rule.("error", context) ==
               Error.new("the expected error", context)
    end

    test "returns a valid rule with a 1-arity error function" do
      test_rule =
        rule(
          fn value -> value == "ok" end,
          fn value -> "#{value} is wrong" end
        )

      context = ["my", "context"]

      assert test_rule.("ok", context) == []

      assert test_rule.("plop", context) ==
               Error.new("plop is wrong", context)
    end

    test "returns a valid rule with a 2-arity error function" do
      test_rule =
        rule(
          fn value -> value == "ok" end,
          fn value, context -> "#{value} is wrong in #{context}" end
        )

      context = ["my", "context"]

      assert test_rule.("ok", context) == []

      assert test_rule.("plop", context) ==
               Error.new("plop is wrong in mycontext", context)
    end
  end

  describe "predefined rule" do
    test "one_of/1 validates that value is in the options" do
      test_rule = one_of([1, 2, 3])
      assert test_rule.(1, []) == []

      assert one_of([1, 2, 3]).(7, []) ==
               Error.new("Invalid value '7'. Valid options: [1, 2, 3]", [])
    end

    test "is_integer_type/0 validates that value is an integer" do
      assert is_integer_type().(14, []) == []
      assert is_integer_type().(14.5, []) == Error.new("Expected an integer, received: 14.5.", [])

      assert is_integer_type().("plop", []) ==
               Error.new("Expected an integer, received: \"plop\".", [])
    end

    test "is_string_type/0 validates that value is a string" do
      assert is_string_type().("plop", []) == []
      assert is_string_type().(14.5, []) == Error.new("Expected a string, received: 14.5.", [])

      assert is_string_type().(:bim, []) ==
               Error.new("Expected a string, received: :bim.", [])
    end

    test "is_float_type/0 validates that value is a float" do
      assert is_float_type().(14.5, []) == []
      assert is_float_type().(14, []) == Error.new("Expected a float, received: 14.", [])

      assert is_float_type().("plop", []) ==
               Error.new("Expected a float, received: \"plop\".", [])
    end

    test "is_number_type/0 validates that value is a number" do
      assert is_number_type().(14.5, []) == []
      assert is_number_type().(14, []) == []

      assert is_number_type().("plop", []) ==
               Error.new("Expected a number, received: \"plop\".", [])
    end

    test "is_boolean_type/0 validates that value is a boolean" do
      assert is_boolean_type().(true, []) == []
      assert is_boolean_type().(false, []) == []

      assert is_boolean_type().("true", []) ==
               Error.new("Expected a boolean, received: \"true\".", [])

      assert is_boolean_type().(1, []) ==
               Error.new("Expected a boolean, received: 1.", [])
    end

    test "min_length/1 validates the length of a string" do
      test_rule = min_length(5)

      assert test_rule.("hey", []) == Error.new("Minimum length of 5 required (current: 3).", [])
      assert test_rule.("hell", []) == Error.new("Minimum length of 5 required (current: 4).", [])
      assert test_rule.("hello", []) == []
    end

    test "min_length/1 validates the length of a list" do
      test_rule = min_length(5)

      assert test_rule.([1, 2, 3], []) ==
               Error.new("Minimum length of 5 required (current: 3).", [])

      assert test_rule.([1, 2, 3, 4], []) ==
               Error.new("Minimum length of 5 required (current: 4).", [])

      assert test_rule.([1, 2, 3, 4, 5], []) == []
    end

    test "max_length/1 validates the length of a string" do
      test_rule = max_length(4)

      assert test_rule.("hey", []) == []
      assert test_rule.("hell", []) == []

      assert test_rule.("hello", []) ==
               Error.new("Maximum length of 4 required (current: 5).", [])
    end

    test "max_length/1 validates the length of a list" do
      test_rule = max_length(4)

      assert test_rule.([1, 2, 3], []) == []
      assert test_rule.([1, 2, 3, 4], []) == []

      assert test_rule.([1, 2, 3, 4, 5], []) ==
               Error.new("Maximum length of 4 required (current: 5).", [])
    end

    test "non_empty/0 validates that the string is not empty" do
      test_rule = non_empty()

      assert test_rule.("", []) == Error.new("Value cannot be empty.", [])
      assert test_rule.("hello", []) == []
    end

    test "non_empty/0 validates that the list is not empty" do
      test_rule = non_empty()

      assert test_rule.([], []) == Error.new("Value cannot be empty.", [])
      assert test_rule.([1, 2, 3], []) == []
    end

    test "exact_length/1 validates the length of a string" do
      test_rule = exact_length(4)

      assert test_rule.("hey", []) == Error.new("Expected length of 4 (current: 3).", [])
      assert test_rule.("hell", []) == []
      assert test_rule.("hello", []) == Error.new("Expected length of 4 (current: 5).", [])
    end

    test "exact_length/1 validates the length of a list" do
      test_rule = exact_length(4)

      assert test_rule.([1, 2, 3], []) == Error.new("Expected length of 4 (current: 3).", [])
      assert test_rule.([1, 2, 3, 4], []) == []

      assert test_rule.([1, 2, 3, 4, 5], []) ==
               Error.new("Expected length of 4 (current: 5).", [])
    end

    test "no_duplicates/0 detects duplicates in a list" do
      assert no_duplicate().([1, 5, 3, 2, 7], []) == []

      assert no_duplicate().([1, 5, 3, 5, 7, 3, 3], []) ==
               Error.new("The list should not contain duplicates (duplicates found: [5, 3]).", [])
    end

    test "match/1 validates string against a regex" do
      test_rule = match(~r/^hel/)

      assert test_rule.("hello", []) == []
      assert test_rule.("helicopter", []) == []
      assert test_rule.("heyy", []) == Error.new("Value heyy does not match regex ~r/^hel/.", [])
    end

    test "match/1 accepts a string for the regex" do
      test_rule = match("^hel")

      assert test_rule.("hello", []) == []
      assert test_rule.("helicopter", []) == []
      assert test_rule.("heyy", []) == Error.new("Value heyy does not match regex ~r/^hel/.", [])
    end

    test "min/1 detects when value is too low" do
      test_rule = min(10)

      assert test_rule.(15, []) == []
      assert test_rule.(10, []) == []
      assert test_rule.(9, []) == Error.new("Must be greater than or equal to 10.", [])
    end

    test "max/1 detects when value is too high" do
      test_rule = max(10)

      assert test_rule.(5, []) == []
      assert test_rule.(10, []) == []
      assert test_rule.(11, []) == Error.new("Must be less than or equal to 10.", [])
    end

    test "between/2 detects when value is out of range" do
      test_rule = between(3, 6)

      assert test_rule.(2, []) == Error.new("Must be between 3 and 6.", [])
      assert test_rule.(3, []) == []
      assert test_rule.(5, []) == []
      assert test_rule.(6, []) == []
      assert test_rule.(7, []) == Error.new("Must be between 3 and 6.", [])
    end
  end
end
