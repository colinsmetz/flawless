defmodule Validator.UnionTest do
  use ExUnit.Case, async: true
  alias Validator.Union
  import Validator.Helpers

  test "it flattens schemas correctly" do
    assert Union.flatten([string(), number(), atom()]) == [string(), number(), atom()]
    assert Union.flatten([string(), [number()], {atom()}]) == [string(), [number()], {atom()}]

    assert Union.flatten([%Union{schemas: [string(), [number()]]}, atom()]) == [
             string(),
             [number()],
             atom()
           ]

    assert Union.flatten([%Union{schemas: [string(), %Union{schemas: [number()]}]}, atom()]) == [
             string(),
             number(),
             atom()
           ]
  end

  test "it deduplicates schemas" do
    assert Union.flatten([string(), number(), string()]) == [string(), number()]
  end
end
