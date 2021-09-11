defmodule Validator.InspectTest do
  use ExUnit.Case, async: true
  import Validator.Helpers
  import Validator.Rule

  test "can inspect complex schemas" do
    schema = %{
      "a" => number(),
      "b" => string(check: min_length(2), cast_from: [:integer, :atom]),
      "c" => value(),
      "d" => literal(19),
      "e" => list(string(), non_empty: true, no_duplicate: true),
      "f" => tuple({number(), atom()}),
      "g" => map(%{z: pid()}),
      maybe("h") => atom(),
      any_key() => string()
    }

    assert inspect(schema, pretty: true) <> "\n" == ~s"""
           %{
             any_key() => string(),
             maybe("h") => atom(),
             "a" => number(),
             "b" => string(checks: #1, cast_from: [:integer, :atom]),
             "c" => any(),
             "d" => literal(19),
             "e" => list(string(), checks: #2),
             "f" => tuple({number(), atom()}),
             "g" => map(%{z: pid()})
           }
           """
  end
end
