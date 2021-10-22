defmodule Flawless.Types.TimeTest do
  use ExUnit.Case, async: true
  alias Flawless.Error
  import Flawless.Helpers
  import Flawless, only: [validate: 2]

  describe "date helper" do
    test "validates that the input is a Time struct" do
      assert validate(Time.utc_now(), time()) == []

      assert validate(DateTime.utc_now(), time()) == [
               Error.new("Expected struct of type: Time, got struct of type: DateTime.", [])
             ]

      assert validate("2015-01-23", time()) == [
               Error.new("Expected type: Time, got: \"2015-01-23\".", [])
             ]
    end

    test "can cast from an ISO8601 string" do
      assert validate("23:50:07", time(cast_from: :string)) == []

      assert validate("2015", time(cast_from: :string)) == [
               Error.new("Cannot be cast to Time.", [])
             ]
    end

    test "can cast from a number of seconds" do
      assert validate(1_596, time(cast_from: :integer)) == []
    end

    test "cannot cast from other types" do
      assert validate(:"23:50:07", time(cast_from: :atom)) == [
               Error.new("Cannot be cast to Time.", [])
             ]
    end

    test "supports the 'after' rule" do
      assert validate(~T[09:02:05], time(after: ~T[15:45:00])) == [
               Error.new("The time should be later than 15:45:00.", [])
             ]

      assert validate(~T[16:00:00], time(after: ~T[15:45:00])) == []
    end

    test "supports the 'before' rule" do
      assert validate(~T[18:23:56], time(before: ~T[15:45:00])) == [
               Error.new("The time should be earlier than 15:45:00.", [])
             ]

      assert validate(~T[02:05:00], time(before: ~T[15:45:00])) == []
    end

    test "supports the 'between' rule" do
      assert validate(~T[08:00:01], time(between: [~T[15:45:00], ~T[17:00:00]])) == [
               Error.new(
                 "The time should be comprised between 15:45:00 and 17:00:00.",
                 []
               )
             ]

      assert validate(~T[08:30:00], time(between: [~T[08:00:00], ~T[09:00:00]])) == []
      assert validate(~T[01:00:00], time(between: [~T[22:00:00], ~T[04:00:00]])) == []
    end

    test "can be nillable" do
      assert validate(nil, time(nil: true)) == []
    end
  end
end
