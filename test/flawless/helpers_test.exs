defmodule Flawless.HelpersTest do
  defmodule User do
    defstruct [:name, :age]
  end

  use ExUnit.Case, async: true
  alias __MODULE__.User
  import Flawless.Helpers
  doctest Flawless.Helpers
end
