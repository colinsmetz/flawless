defmodule Validator.TypesTest do
  use ExUnit.Case, async: true
  import Validator.Types

  test "has_type?/2 checks the type of a value" do
    assert has_type?(12, :any) == true
    assert has_type?("plop", :any) == true

    assert has_type?("plop", :string) == true
    assert has_type?(:bim, :string) == false
    assert has_type?(898, :string) == false

    assert has_type?("plop", :number) == false
    assert has_type?(:bim, :number) == false
    assert has_type?(898, :number) == true
    assert has_type?(9.99, :number) == true

    assert has_type?("plop", :integer) == false
    assert has_type?(:bim, :integer) == false
    assert has_type?(898, :integer) == true
    assert has_type?(9.99, :integer) == false

    assert has_type?("plop", :float) == false
    assert has_type?(:bim, :float) == false
    assert has_type?(898, :float) == false
    assert has_type?(9.99, :float) == true

    assert has_type?("plop", :boolean) == false
    assert has_type?(true, :boolean) == true
    assert has_type?(false, :boolean) == true
    assert has_type?(898, :boolean) == false

    assert has_type?("plop", :atom) == false
    assert has_type?(:bim, :atom) == true
    assert has_type?(898, :atom) == false

    assert has_type?("plop", :list) == false
    assert has_type?([:bim], :list) == true
    assert has_type?([1, 2, 3], :list) == true
    assert has_type?(898, :list) == false

    assert has_type?("plop", :tuple) == false
    assert has_type?({:bim}, :tuple) == true
    assert has_type?({1, 2, 3}, :tuple) == true
    assert has_type?(898, :tuple) == false

    assert has_type?("plop", :map) == false
    assert has_type?({:bim}, :map) == false
    assert has_type?(%{}, :map) == true
    assert has_type?(%{"a" => 17, b: 99}, :map) == true
    assert has_type?(898, :map) == false
  end

  test "type_of determines the type of a value" do
    assert type_of("hi") == :string
    assert type_of(10) == :integer
    assert type_of(10.0) == :float
    assert type_of(true) == :boolean
    assert type_of(:ok) == :atom
    assert type_of([1, 2]) == :list
    assert type_of({1, 2}) == :tuple
    assert type_of(%{c: 3}) == :map
    assert type_of(make_ref()) == :any
  end

  test "cast/3 can cast from one type to another" do
    assert cast("hello", :string, :string) == {:ok, "hello"}
    assert cast(189.6, :number, :string) == {:ok, "189.6"}
    assert cast(12, :integer, :string) == {:ok, "12"}
    assert cast(9.33, :float, :string) == {:ok, "9.33"}
    assert cast(true, :boolean, :string) == {:ok, "true"}
    assert cast(:erlang, :atom, :string) == {:ok, "erlang"}

    assert cast("123", :string, :number) == {:ok, 123}
    assert cast(88.0, :number, :number) == {:ok, 88.0}
    assert cast(123, :integer, :number) == {:ok, 123}
    assert cast(9.01, :float, :number) == {:ok, 9.01}

    assert cast("123", :string, :integer) == {:ok, 123}
    assert cast(58.0, :number, :integer) == {:ok, 58}
    assert cast(999, :integer, :integer) == {:ok, 999}
    assert cast(5.0, :float, :integer) == {:ok, 5}

    assert cast("3.14159", :string, :float) == {:ok, 3.14159}
    assert cast(56, :number, :float) == {:ok, 56.0}
    assert cast(23, :integer, :float) == {:ok, 23.0}
    assert cast(8.99, :float, :float) == {:ok, 8.99}

    assert cast("false", :string, :boolean) == {:ok, false}
    assert cast(false, :boolean, :boolean) == {:ok, false}

    assert cast("jelly", :string, :atom) == {:ok, :jelly}
    assert cast(:not_found, :atom, :atom) == {:ok, :not_found}

    assert cast([1, 2], :list, :list) == {:ok, [1, 2]}
    assert cast({1, 2, 8}, :tuple, :list) == {:ok, [1, 2, 8]}

    assert cast([4, 5, 6], :list, :tuple) == {:ok, {4, 5, 6}}
    assert cast({1, 2}, :tuple, :tuple) == {:ok, {1, 2}}

    assert cast(%{c: 3}, :map, :map) == {:ok, %{c: 3}}
  end

  test "cast/3 returns an error if cast is not possible" do
    assert cast([1, 2], :list, :string) == {:error, "Cannot be cast to string."}
    assert cast({1, 2, 3}, :tuple, :string) == {:error, "Cannot be cast to string."}
    assert cast(%{c: 3}, :map, :string) == {:error, "Cannot be cast to string."}

    assert cast(true, :boolean, :number) == {:error, "Cannot be cast to number."}
    assert cast(:"888", :atom, :number) == {:error, "Cannot be cast to number."}
    assert cast([123], :list, :number) == {:error, "Cannot be cast to number."}
    assert cast({12}, :tuple, :number) == {:error, "Cannot be cast to number."}
    assert cast(%{1 => 1}, :map, :number) == {:error, "Cannot be cast to number."}

    assert cast(true, :boolean, :integer) == {:error, "Cannot be cast to integer."}
    assert cast(:"888", :atom, :integer) == {:error, "Cannot be cast to integer."}
    assert cast([123], :list, :integer) == {:error, "Cannot be cast to integer."}
    assert cast({12}, :tuple, :integer) == {:error, "Cannot be cast to integer."}
    assert cast(%{1 => 1}, :map, :integer) == {:error, "Cannot be cast to integer."}

    assert cast(true, :boolean, :float) == {:error, "Cannot be cast to float."}
    assert cast(:"1.2", :atom, :float) == {:error, "Cannot be cast to float."}
    assert cast([1.2], :list, :float) == {:error, "Cannot be cast to float."}
    assert cast({1.2}, :tuple, :float) == {:error, "Cannot be cast to float."}
    assert cast(%{1 => 2.0}, :map, :float) == {:error, "Cannot be cast to float."}

    assert cast(0, :number, :boolean) == {:error, "Cannot be cast to boolean."}
    assert cast(1, :integer, :boolean) == {:error, "Cannot be cast to boolean."}
    assert cast(1.0, :float, :boolean) == {:error, "Cannot be cast to boolean."}
    assert cast(true, :atom, :boolean) == {:error, "Cannot be cast to boolean."}
    assert cast([true], :list, :boolean) == {:error, "Cannot be cast to boolean."}
    assert cast({false}, :tuple, :boolean) == {:error, "Cannot be cast to boolean."}
    assert cast(%{true => false}, :map, :boolean) == {:error, "Cannot be cast to boolean."}

    assert cast(454, :number, :atom) == {:error, "Cannot be cast to atom."}
    assert cast(78, :integer, :atom) == {:error, "Cannot be cast to atom."}
    assert cast(1.3, :float, :atom) == {:error, "Cannot be cast to atom."}
    assert cast(true, :boolean, :atom) == {:error, "Cannot be cast to atom."}
    assert cast([:ok], :list, :atom) == {:error, "Cannot be cast to atom."}
    assert cast({:ok}, :tuple, :atom) == {:error, "Cannot be cast to atom."}
    assert cast(%{a: :a}, :map, :atom) == {:error, "Cannot be cast to atom."}

    assert cast("[]", :string, :list) == {:error, "Cannot be cast to list."}
    assert cast(78, :number, :list) == {:error, "Cannot be cast to list."}
    assert cast(33, :integer, :list) == {:error, "Cannot be cast to list."}
    assert cast(0.2, :float, :list) == {:error, "Cannot be cast to list."}
    assert cast(true, :boolean, :list) == {:error, "Cannot be cast to list."}
    assert cast(:list, :atom, :list) == {:error, "Cannot be cast to list."}
    assert cast(%{c: 3}, :map, :list) == {:error, "Cannot be cast to list."}

    assert cast("{}", :string, :tuple) == {:error, "Cannot be cast to tuple."}
    assert cast(12, :number, :tuple) == {:error, "Cannot be cast to tuple."}
    assert cast(12, :integer, :tuple) == {:error, "Cannot be cast to tuple."}
    assert cast(3.2, :float, :tuple) == {:error, "Cannot be cast to tuple."}
    assert cast(true, :boolean, :tuple) == {:error, "Cannot be cast to tuple."}
    assert cast(:{}, :atom, :tuple) == {:error, "Cannot be cast to tuple."}
    assert cast(%{}, :map, :tuple) == {:error, "Cannot be cast to tuple."}

    assert cast("%{}", :string, :map) == {:error, "Cannot be cast to map."}
    assert cast(12, :number, :map) == {:error, "Cannot be cast to map."}
    assert cast(12, :integer, :map) == {:error, "Cannot be cast to map."}
    assert cast(12.0, :float, :map) == {:error, "Cannot be cast to map."}
    assert cast(false, :boolean, :map) == {:error, "Cannot be cast to map."}
    assert cast(:%{}, :atom, :map) == {:error, "Cannot be cast to map."}
    assert cast([1, 2], :list, :map) == {:error, "Cannot be cast to map."}
    assert cast({1, 2}, :tuple, :map) == {:error, "Cannot be cast to map."}
  end
end
