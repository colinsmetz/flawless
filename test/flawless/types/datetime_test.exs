defmodule Flawless.Types.DateTimeTest do
  use ExUnit.Case, async: true
  alias Flawless.Error
  import Flawless.Helpers
  import Flawless, only: [validate: 2]

  describe "datetime helper" do
    test "validates that the input is a DateTime struct" do
      assert validate(DateTime.utc_now(), datetime()) == []

      assert validate(Date.utc_today(), datetime()) == [
               Error.new("Expected struct of type: DateTime, got struct of type: Date.", [])
             ]

      assert validate("2015-01-23T23:50:07Z", datetime()) == [
               Error.new("Expected type: DateTime, got: \"2015-01-23T23:50:07Z\".", [])
             ]
    end

    test "can cast from an ISO8601 string" do
      assert validate("2015-01-23T23:50:07Z", datetime(cast_from: :string)) == []

      assert validate("2015", datetime(cast_from: :string)) == [
               Error.new("Cannot be cast to DateTime.", [])
             ]
    end

    test "can cast from a timestamp integer" do
      assert validate(1_596_324_872, datetime(cast_from: :integer)) == []

      assert validate(-5_000_000_000_000, datetime(cast_from: :integer)) == [
               Error.new("Cannot be cast to DateTime.", [])
             ]
    end

    test "cannot cast from other types" do
      assert validate(:"2015-01-23T23:50:07Z", datetime(cast_from: :atom)) == [
               Error.new("Cannot be cast to DateTime.", [])
             ]
    end

    test "supports the 'after' rule" do
      assert validate(~U[2011-01-23 23:50:07Z], datetime(after: ~U[2015-01-23 23:50:07Z])) == [
               Error.new("The datetime should be later than 2015-01-23 23:50:07Z.", [])
             ]

      assert validate(~U[2017-02-24 23:50:07Z], datetime(after: ~U[2015-01-23 23:50:07Z])) == []
    end

    test "supports the 'before' rule" do
      assert validate(~U[2017-02-24 23:50:07Z], datetime(before: ~U[2015-01-23 23:50:07Z])) == [
               Error.new("The datetime should be earlier than 2015-01-23 23:50:07Z.", [])
             ]

      assert validate(~U[2011-01-23 23:50:07Z], datetime(before: ~U[2015-01-23 23:50:07Z])) == []
    end

    test "supports the 'between' rule" do
      assert validate(
               ~U[2017-02-24 23:50:07Z],
               datetime(between: [~U[2015-01-23 23:50:07Z], ~U[2015-02-23 23:50:07Z]])
             ) == [
               Error.new(
                 "The datetime should be comprised between 2015-01-23 23:50:07Z and 2015-02-23 23:50:07Z.",
                 []
               )
             ]

      assert validate(
               ~U[2015-02-03 23:33:07Z],
               datetime(between: [~U[2015-01-23 23:50:07Z], ~U[2015-02-23 23:50:07Z]])
             ) == []
    end

    test "can be nillable" do
      assert validate(nil, datetime(nil: true)) == []
    end
  end
end
