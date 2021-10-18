defmodule Validator.HelpersTest do
  defmodule User do
    defstruct [:name, :age]
  end

  use ExUnit.Case, async: true
  alias __MODULE__.User
  import Validator.Helpers
  doctest Validator.Helpers
end
