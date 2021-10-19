defmodule Validator.SchemaValidatorTest do
  use ExUnit.Case, async: true
  doctest Validator.SchemaValidator
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
        "format" => string(checks: [one_of(["csv", "xml"])]),
        "regex" => string(),
        "bim" => %{
          "truc" => string()
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
                "name" => string(),
                "type" => string(),
                "is_key" => boolean(),
                "is_required" => boolean(),
                "meta" =>
                  map(%{
                    "id" => value()
                  })
              },
              checks: []
            ),
            checks: [rule(&(length(&1) > 0), "Fields must contain at least one item")]
          ),
        "brands" => [string()],
        "status" => atom(checks: [one_of([:ok, :error])]),
        "tuple_of_things" => {
          [string()],
          %{"a" => string()}
        }
      }

      assert validate_schema(schema) == []
    end

    test "it detects errors in invalid schemas" do
      schema = %{
        "name" => string(nil: :maybe, cast_from: :nothing),
        "projects" => [string(), string()],
        "profile" => %{
          "tags" => list(string(), checks: [fn -> 0 end])
        },
        "process" => self()
      }

      assert validate_schema(schema) == [
               Error.new(
                 "The list shortcut `[item_spec]` should define only one schema that will be the same for all items.",
                 ["projects"]
               ),
               Error.new("Predicates used in checks must be function of arity 1.", ["profile", "tags", :checks, 0]),
               Error.new("Value does not match any of the possible schemas.", ["process"]),
               Error.new("Invalid value: :maybe. Valid options: [:default, true, false]", [
                 "name",
                 nil
               ]),
               Error.new(
                 "Invalid value: :nothing. Valid options: [:any, :string, :number, :integer, :float, :boolean, :atom, :pid, :ref, :function, :port, :list, :tuple, :map, :struct]",
                 ["name", :cast_from]
               )
             ]
    end
  end
end
