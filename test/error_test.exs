defmodule Validator.ErrorTest do
  use ExUnit.Case, async: true
  alias Validator.Error

  test "new/2 builds a valid error" do
    assert Error.new("my test error", ["a", "b"]) == %Error{
             message: "my test error",
             context: ["a", "b"]
           }
  end
end
