defmodule Flawless.Types.DateTest do
  use ExUnit.Case, async: true
  alias Flawless.Error
  import Flawless.Helpers
  import Flawless, only: [validate: 2]

  describe "date helper" do
    test "validates that the input is a Date struct" do
      assert validate(Date.utc_today(), date()) == []

      assert validate(DateTime.utc_now(), date()) == [
               Error.new("Expected struct of type: Date, got struct of type: DateTime.", [])
             ]

      assert validate("2015-01-23", date()) == [
               Error.new("Expected type: Date, got: \"2015-01-23\".", [])
             ]
    end

    test "can cast from an ISO8601 string" do
      assert validate("2015-01-23", date(cast_from: :string)) == []

      assert validate("2015", date(cast_from: :string)) == [
               Error.new("Cannot be cast to Date.", [])
             ]
    end

    test "can cast from a number of gregorian days" do
      assert validate(1_596, date(cast_from: :integer)) == []

      assert validate(-5_000_000_000_000, date(cast_from: :integer)) == [
               Error.new("Cannot be cast to Date.", [])
             ]
    end

    test "cannot cast from other types" do
      assert validate(:"2015-01-23", date(cast_from: :atom)) == [
               Error.new("Cannot be cast to Date.", [])
             ]
    end

    test "supports the 'after' rule" do
      assert validate(~D[2011-01-23], date(after: ~D[2015-01-23])) == [
               Error.new("The date should be later than 2015-01-23.", [])
             ]

      assert validate(~D[2017-02-24], date(after: ~D[2015-01-23])) == []
    end

    test "supports the 'before' rule" do
      assert validate(~D[2017-02-24], date(before: ~D[2015-01-23])) == [
               Error.new("The date should be earlier than 2015-01-23.", [])
             ]

      assert validate(~D[2011-01-23], date(before: ~D[2015-01-23])) == []
    end

    test "supports the 'between' rule" do
      assert validate(~D[2017-02-24], date(between: [~D[2015-01-23], ~D[2015-02-23]])) == [
               Error.new(
                 "The date should be comprised between 2015-01-23 and 2015-02-23.",
                 []
               )
             ]

      assert validate(
               ~D[2015-02-03],
               date(between: [~D[2015-01-23], ~D[2015-02-23]])
             ) == []
    end

    test "can be nillable" do
      assert validate(nil, date(nil: true)) == []
    end
  end
end
