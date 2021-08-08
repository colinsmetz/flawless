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
  end
end
