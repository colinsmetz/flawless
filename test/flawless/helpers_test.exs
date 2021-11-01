defmodule Flawless.HelpersTest do
  defmodule User do
    defstruct [:name, :age]
  end

  use ExUnit.Case, async: true
  alias __MODULE__.User
  import Flawless.Helpers
  doctest Flawless.Helpers

  describe "modifiers" do
    test "can modify a Spec" do
      schema = atom()
      expected_schema = atom(nil: true, on_error: "Wrong.", in: [:ok, :error])

      assert expected_schema ==
               schema |> add_opts(on_error: "Wrong.", nil: true, in: [:ok, :error])
    end

    test "keeps the existing checks" do
      schema = integer(min: 0)
      expected_schema = integer(min: 0, max: 10, cast_from: [:string])
      assert expected_schema == schema |> add_opts(cast_from: :string, max: 10)
    end

    test "keeps the existing cast_from" do
      schema = integer(min: 0, cast_from: :float)
      expected_schema = integer(min: 0, cast_from: [:float, :string])
      assert expected_schema == schema |> add_opts(cast_from: :string)
    end

    test "can modify a list shortcut" do
      schema = [string()]
      expected_schema = list(string(), max_length: 10, nil: false)
      assert expected_schema == schema |> add_opts(nil: false, max_length: 10)
    end

    test "can modify a tuple shortcut" do
      schema = {atom(), any()}
      fake_check = fn _ -> :ok end
      expected_schema = tuple({atom(), any()}, on_error: "hey", late_check: fake_check)
      assert expected_schema == schema |> add_opts(late_checks: [fake_check], on_error: "hey")
    end

    test "can modify a struct shortcut" do
      schema = %User{name: string(), age: integer()}
      expected_schema = structure(%User{name: string(), age: integer()}, nil: true)
      assert expected_schema == schema |> add_opts(nil: true)
    end

    test "can modify a map shortcut" do
      schema = %{name: string(), age: integer()}
      expected_schema = map(%{name: string(), age: integer()}, nil: true)
      assert expected_schema == schema |> add_opts(nil: true)
    end

    test "can modify a literal" do
      schema = 18
      expected_schema = literal(18, on_error: "bim")
      assert expected_schema == schema |> add_opts(on_error: "bim")
    end
  end
end
