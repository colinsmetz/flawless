defmodule Validator.SchemaValidatorTest do
  use ExUnit.Case, async: true
  doctest Validator
  import Validator, only: [validate_schema: 1]
  alias Validator.SchemaValidator
  alias Validator.Error

  import Validator.Helpers
  import Validator.Rule

  describe "schema_schema/0" do
    test "it validates itself" do
      assert validate_schema(SchemaValidator.schema_schema()) == []
    end

    test "it successfully validates complex schemas" do
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
              checks: []
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

      assert validate_schema(schema) == []
    end

    test "it detects errors in invalid schemas" do
      bad_check = fn -> 0 end

      schema = %{
        "name" => string(required: :maybe, cast_from: :nothing),
        "projects" => [string(), string()],
        "profile" => %{
          "tags" => list(string(), checks: [bad_check])
        },
        "process" => self()
      }

      assert validate_schema(schema) == [
               Error.new(
                 "Invalid value: :nothing. Valid options: [:any, :string, :number, :integer, :float, :boolean, :atom, :pid, :ref, :function, :port, :list, :tuple, :map, :struct]",
                 ["name", :cast_from]
               ),
               Error.new("Expected type: boolean, got: :maybe.", ["name", :required]),
               Error.new("Value does not match any of the possible schemas.", ["process"]),
               Error.new("Expected type: struct, got: #{inspect(bad_check)}.", [
                 "profile",
                 "tags",
                 :checks,
                 0
               ]),
               Error.new("Maximum length of 1 required (current: 2).", ["projects"])
             ]
    end
  end
end
