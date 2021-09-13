defmodule Validator.Types.NaiveDateTimeTest do
  use ExUnit.Case, async: true
  alias Validator.Error
  import Validator.Helpers
  import Validator, only: [validate: 2]

  describe "datetime helper" do
    test "validates that the input is a NaiveDateTime struct" do
      assert validate(NaiveDateTime.utc_now(), naive_datetime()) == []

      assert validate(DateTime.utc_now(), naive_datetime()) == [
               Error.new(
                 "Expected struct of type: NaiveDateTime, got struct of type: DateTime.",
                 []
               )
             ]

      assert validate("2015-01-23T23:50:07", naive_datetime()) == [
               Error.new("Expected type: NaiveDateTime, got: \"2015-01-23T23:50:07\".", [])
             ]
    end

    test "can cast from an ISO8601 string" do
      assert validate("2015-01-23T23:50:07", naive_datetime(cast_from: :string)) == []

      assert validate("2015", naive_datetime(cast_from: :string)) == [
               Error.new("Cannot be cast to NaiveDateTime.", [])
             ]
    end

    test "can cast from a number of gregorian seconds" do
      assert validate(1_596_324_872, naive_datetime(cast_from: :integer)) == []

      assert validate(-5_000_000_000_000, naive_datetime(cast_from: :integer)) == [
               Error.new("Cannot be cast to NaiveDateTime.", [])
             ]
    end

    test "cannot cast from other types" do
      assert validate(:"2015-01-23T23:50:07", naive_datetime(cast_from: :atom)) == [
               Error.new("Cannot be cast to NaiveDateTime.", [])
             ]
    end

    test "supports the 'after' rule" do
      assert validate(~N[2011-01-23 23:50:07], naive_datetime(after: ~N[2015-01-23 23:50:07])) ==
               [
                 Error.new("The naive datetime should be later than 2015-01-23 23:50:07.", [])
               ]

      assert validate(~N[2017-02-24 23:50:07], naive_datetime(after: ~N[2015-01-23 23:50:07])) ==
               []
    end

    test "supports the 'before' rule" do
      assert validate(~N[2017-02-24 23:50:07], naive_datetime(before: ~N[2015-01-23 23:50:07])) ==
               [
                 Error.new("The naive datetime should be earlier than 2015-01-23 23:50:07.", [])
               ]

      assert validate(~N[2011-01-23 23:50:07], naive_datetime(before: ~N[2015-01-23 23:50:07])) ==
               []
    end

    test "supports the 'between' rule" do
      assert validate(
               ~N[2017-02-24 23:50:07],
               naive_datetime(between: [~N[2015-01-23 23:50:07], ~N[2015-02-23 23:50:07]])
             ) == [
               Error.new(
                 "The naive datetime should be comprised between 2015-01-23 23:50:07 and 2015-02-23 23:50:07.",
                 []
               )
             ]

      assert validate(
               ~N[2015-02-03 23:33:07],
               naive_datetime(between: [~N[2015-01-23 23:50:07], ~N[2015-02-23 23:50:07]])
             ) == []
    end

    test "can be nillable" do
      assert validate(nil, naive_datetime(nil: true)) == []
    end
  end
end
