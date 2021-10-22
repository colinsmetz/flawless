defmodule Flawless.ErrorTest do
  use ExUnit.Case, async: true
  alias Flawless.Error

  test "new/2 builds a valid error" do
    assert Error.new("my test error", ["a", "b"]) == %Error{
             message: "my test error",
             context: ["a", "b"]
           }
  end

  test "message_from_template/2 replaces interpolated variables" do
    assert Error.message_from_template("String %{value} must have at least %{n} characters.",
             n: 10,
             value: "plop"
           ) == "String plop must have at least 10 characters."

    assert Error.message_from_template("Value %{x} is displayed here. Value %{x} is also here.",
             x: 99
           ) == "Value 99 is displayed here. Value 99 is also here."

    assert Error.message_from_template("A list: %{list}", list: inspect([1, 2, 3])) ==
             "A list: [1, 2, 3]"
  end
end
