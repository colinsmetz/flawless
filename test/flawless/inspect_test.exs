defmodule Flawless.InspectTest do
  use ExUnit.Case, async: true
  import Flawless.Helpers
  import Flawless.Rule

  defmodule ForTest do
    defstruct x: nil, y: nil
  end

  test "can inspect complex schemas" do
    schema = %{
      "a" => number(),
      "b" => string(check: min_length(2), cast_from: [:integer, :atom]),
      "c" => any(),
      "d" => literal(19),
      "e" => list(string(), non_empty: true, no_duplicate: true),
      "f" => tuple({number(), atom()}, nil: true),
      "g" => map(%{z: pid()}),
      "h" => structure(%ForTest{x: string(), y: function()}),
      "i" => union([string(), number()]),
      maybe("z") => atom(late_check: one_of([:a, :b])),
      any_key() => string()
    }

    assert inspect(schema, pretty: true) <> "\n" == ~s"""
           %{
             any_key() => string(),
             maybe("z") => atom(late_checks: #1),
             "a" => number(),
             "b" => string(checks: #1, cast_from: [:integer, :atom]),
             "c" => any(),
             "d" => literal(19),
             "e" => list(string(), checks: #2),
             "f" => tuple({number(), atom()}, nil: true),
             "g" => map(%{z: pid()}),
             "h" => struct(%Flawless.InspectTest.ForTest{x: string(), y: function()}),
             "i" => union([string(), number()])
           }
           """
  end
end
