defmodule Validator.Helpers do
  @moduledoc """

  A series of helper functions to build schemas.

  ## Common options

  * `checks`: a list of checks.
  * `check`: a single check. Can be repeated.
  * `late_checks`: a list of checks to evaluate only if all other checks passed on that element.
  * `late_check`: a single late check. Can be repeated.
  * `nil`: whether the value is nillable.
  * `cast_from`: the types from which it is allowed to cast the value to the expected type.

  """
  alias Validator.Rule
  alias Validator.Types
  alias Validator.Spec
  alias Validator.{AnyOtherKey, OptionalKey}

  defp value_with_type(type, opts) do
    opts
    |> Keyword.put(:type, type)
    |> value()
  end

  defp extract_checks(opts, type) do
    opts
    |> Keyword.get(:checks, [])
    |> Enum.concat(Keyword.get_values(opts, :check))
    |> Enum.concat(built_in_checks(opts, type))
  end

  defp extract_late_checks(opts) do
    opts
    |> Keyword.get(:late_checks, [])
    |> Enum.concat(Keyword.get_values(opts, :late_check))
  end

  defp build_spec(subspec, type, opts) do
    %Spec{
      checks: extract_checks(opts, type),
      late_checks: extract_late_checks(opts),
      type: type,
      cast_from: opts |> Keyword.get(:cast_from, []),
      nil: opts |> Keyword.get(nil, :default),
      for: subspec
    }
  end

  @doc """
  Represents any value.

  ## Options

  - `in` - a list of acceptable values

  Other options are detailed in [Common options](#module-common-options).

  ## Examples

      iex> Validator.validate(:something, value())
      []

      iex> Validator.validate([1, 2, 3], value())
      []

      iex> Validator.validate(2, value(in: [1, "1", :one]))
      [%Validator.Error{context: [], message: "Invalid value: 2. Valid options: [1, \\"1\\", :one]"}]

  """
  @spec value(keyword) :: Validator.Spec.t()
  def value(opts \\ []) do
    type = opts |> Keyword.get(:type, :any)

    %Spec.Value{schema: opts |> Keyword.get(:schema, nil)}
    |> build_spec(type, opts)
  end

  @doc """
  Represents a list, each item conforming to the `item_type` spec.

  ## Options

  - `min_length` - the minimum length the list should have
  - `max_length` - the maximum length the list should have
  - `length` - the exact length the list should have
  - `in` - a list of acceptable values
  - `non_empty` - a boolean to ensure the list is not the empty list `[]`
  - `no_duplicate`- a boolean to ensure that all items in the list are distinct

  Other options are detailed in [Common options](#module-common-options).

  ## Examples

      iex> Validator.validate([1, 2, 3], list(integer()))
      []

      iex> Validator.validate([1, "two", 3], list(integer()))
      [%Validator.Error{context: [1], message: "Expected type: integer, got: \\"two\\"."}]

  ## Shortcuts

  If you do not need any of the options, you can use the `[item_type]` shortcut instead of this
  function. You can also use `[]` for matching any list (equivalent to `list(value())`). For
  matching the empty list, consider using `literal([])` instead.

  """
  @spec list(any, keyword) :: Validator.Spec.t()
  def list(item_type, opts \\ []) do
    %Spec.List{item_type: item_type}
    |> build_spec(:list, opts)
  end

  @doc """
  Represents a tuple.

  The `elem_types` should be a tuple of the expected tuple size, and each element in
  the tuple should be a valid spec that the given element must conform to.

  ## Options

  - `in` - a list of acceptable values

  Other options are detailed in [Common options](#module-common-options).

  ## Examples

      iex> Validator.validate({:ok, 99}, tuple({atom(), number()}))
      []

      iex> Validator.validate({:ok, "hello"}, tuple({atom(), number()}))
      [%Validator.Error{context: [1], message: "Expected type: number, got: \\"hello\\"."}]

      iex> Validator.validate({:ok}, tuple({atom(), number()}))
      [%Validator.Error{context: [], message: "Invalid tuple size (expected: 2, received: 1)."}]

  ## Shortcut

  If you do not need any of the options, you can use `elem_types` tuple alone.

  """
  @spec tuple(any, keyword) :: Validator.Spec.t()
  def tuple(elem_types, opts \\ []) do
    %Spec.Tuple{elem_types: elem_types}
    |> build_spec(:tuple, opts)
  end

  @doc """
  Represents a map with a given `schema`.

  The `schema` should be a map with the expected keys, and the spec for each associated
  value. By default, all the given keys are considered as **required**, and any non-specified
  key is considered as **invalid**. See the subsections below to overcome those limitations.

  If keys are given as atoms, then atom keys are expected. The corresponding string keys will
  not be automatically accepted. And vice versa.

  This function should not be used for validating structs. For structs, use
  [`structure/2`](#structure/2) instead.

  ## Optional keys

  If some keys are allowed but not mandatory, it is possible to define them as *optional*. To
  define an optional key, use the [`maybe/1`](#maybe/1) helper on the key.

  **Note:**

  - Unless the `nil` keyword is explictly defined on the value, the value associated to an
    optional key will be nillable.
  - With atom keys, it is possible to use the `key: value` shortcut instead of `:key => value`.
    If you use `maybe(:key)`, the shortcut cannot be used. Besides, non-optional keys using
    the short **must** be put at the end of the map.

  ## Non-specified keys

  Any key that is not explicitly defined in the map is not accepted by default. If you wish to
  allow them, you should add [`any_key()`](#any_key/0) as one of the keys. Extra fields will then
  be accepted, and they have to comply with the spec associated to `any_key()`.

  ## Options

  - `in` - a list of acceptable values

  Other options are detailed in [Common options](#module-common-options).

  ## Examples

      iex> schema = map(%{
      ...>   name: string(),
      ...>   age: number()
      ...> })
      iex> Validator.validate(%{name: "James", age: 10}, schema)
      []
      iex> Validator.validate(%{age: 25, country: "BE"}, schema)
      [
        %Validator.Error{
          context: [],
          message: [
            "Unexpected fields: [:country].",
            "Missing required fields: :name (string)."
          ]
        }
      ]

      # Optional keys
      iex> schema = map(%{
      ...>   "name" => string(),
      ...>   "age" => number(),
      ...>   maybe("country") => string()
      ...> })
      iex> Validator.validate(%{"name" => "Patty", "age" => 24}, schema)
      []
      iex> Validator.validate(%{"name" => "Patty", "age" => 24, "country" => "DE"}, schema)
      []

      # Extra keys
      iex> schema = map(%{
      ...>   "id" => string(),
      ...>   any_key() => number()
      ...> })
      iex> Validator.validate(%{"id" => "abc"}, schema)
      []
      iex> Validator.validate(%{"id" => "abc", "price" => 9.99, "age" => 10}, schema)
      []
      iex> Validator.validate(%{"price" => 9.99}, schema)
      [%Validator.Error{context: [], message: "Missing required fields: \\"id\\" (string)."}]
      iex> Validator.validate(%{"id" => "abc", "name" => "stuff"}, schema)
      [%Validator.Error{context: ["name"], message: "Expected type: number, got: \\"stuff\\"."}]

  ## Shortcut

  If you do not need any of the options, you can use map schema alone.

  """
  @spec map(any, keyword) :: Validator.Spec.t()
  def map(schema, opts \\ []) do
    opts
    |> Keyword.put(:schema, schema)
    |> Keyword.put(:type, :map)
    |> value()
  end

  @doc """
  Represents an Elixir struct.

  If a schema is given, it should take the form of the expected struct, with values
  replaced by their specs, similarly to `map`.

  If the struct is opaque and the internal fields cannot be validated, the module
  alone can be given instead.

  ## Options

  - `in` - a list of acceptable values

  Other options are detailed in [Common options](#module-common-options).

  ## Examples

  Let's define a struct:

  ```elixir
  defmodule User do
    defstruct [:name, :age]
  end
  ```

      iex> schema = structure(%User{
      ...>   name: string(),
      ...>   age: number()
      ...> })
      iex> Validator.validate(%User{name: "Stephen", age: 55}, schema)
      []
      iex> Validator.validate(%User{name: "Stephen", age: "thirty"}, schema)
      [%Validator.Error{context: [:age], message: "Expected type: number, got: \\"thirty\\"."}]
      iex> Validator.validate(%{name: "Stephen", age: 55}, schema)
      [%Validator.Error{context: [], message: "Expected type: Validator.HelpersTest.User, got: %{age: 55, name: \\"Stephen\\"}."}]

      # Opaque struct
      iex> Validator.validate(%User{name: "Stephen", age: 55}, structure(DateTime))
      [%Validator.Error{context: [], message: "Expected struct of type: DateTime, got struct of type: Validator.HelpersTest.User."}]

  """
  @spec structure(atom | %{:__struct__ => atom, optional(any) => any}, keyword) ::
          Validator.Spec.t()
  def structure(schema_or_module, opts \\ [])

  def structure(%module{} = schema, opts) do
    %Spec.Struct{module: module, schema: schema}
    |> build_spec(:struct, opts)
  end

  def structure(module, opts) when is_atom(module) do
    %Spec.Struct{module: module, schema: nil}
    |> build_spec(:struct, opts)
  end

  @doc """
  Represents a literal value.

  ## Options

  - `in` - a list of acceptable values (useless but present for coherence)

  Other options are detailed in [Common options](#module-common-options).

  ## Examples

      iex> Validator.validate(80, literal(80))
      []

      iex> Validator.validate({1, 2, 3}, literal({1, 2, 3}))
      []

      iex> Validator.validate("hello", literal("bonjour"))
      [%Validator.Error{context: [], message: "Expected literal value \\"bonjour\\", got: \\"hello\\"."}]

  ## Shortcuts

  For numbers, strings, and atoms, the function can be skipped altogether and replaced by
  the value directly.

  """
  @spec literal(any, keyword) :: Validator.Spec.t()
  def literal(value, opts \\ []) do
    type = Types.type_of(value)

    %Spec.Literal{value: value}
    |> build_spec(type, opts)
  end

  @doc """
  Represents an integer.

  ## Options

  - `min` - the minimum acceptable value (included)
  - `max` - the maximum acceptable value (included)
  - `in` - a list of acceptable values
  - `between` - a `[min, max]` range of acceptable values

  Other options are detailed in [Common options](#module-common-options).

  ## Examples

      iex> Validator.validate(100, integer())
      []

      iex> Validator.validate(2.5, integer())
      [%Validator.Error{context: [], message: "Expected type: integer, got: 2.5."}]

      iex> Validator.validate(250, integer(min: 0, max: 100))
      [%Validator.Error{context: [], message: "Must be less than or equal to 100."}]

  """
  @spec integer(keyword) :: Validator.Spec.t()
  def integer(opts \\ []), do: value_with_type(:integer, opts)

  @doc """
  Represents a string.

  ## Options

  - `min_length` - the minimum length the string should have
  - `max_length` - the maximum length the string should have
  - `length` - the exact length the string should have
  - `in` - a list of acceptable values
  - `non_empty` - a boolean to ensure the string is not the empty string `""`
  - `format`- a regex that the string should match

  Other options are detailed in [Common options](#module-common-options).

  ## Examples

      iex> Validator.validate("hello", string())
      []

      iex> Validator.validate(:hello, string())
      [%Validator.Error{context: [], message: "Expected type: string, got: :hello."}]

      iex> Validator.validate("", string(non_empty: true))
      [%Validator.Error{context: [], message: "Value cannot be empty."}]

      iex> Validator.validate("123", string(format: ~r/[0-9]+/))
      []

  """
  @spec string(keyword) :: Validator.Spec.t()
  def string(opts \\ []), do: value_with_type(:string, opts)

  @doc """
  Represents a float.

  ## Options

  - `min` - the minimum acceptable value (included)
  - `max` - the maximum acceptable value (included)
  - `in` - a list of acceptable values
  - `between` - a `[min, max]` range of acceptable values

  Other options are detailed in [Common options](#module-common-options).

  ## Examples

      iex> Validator.validate(3.33, float())
      []

      iex> Validator.validate(3, float())
      [%Validator.Error{context: [], message: "Expected type: float, got: 3."}]

      iex> Validator.validate(-3.33, float(min: 0.0, max: 5.0))
      [%Validator.Error{context: [], message: "Must be greater than or equal to 0.0."}]

  """
  @spec float(keyword) :: Validator.Spec.t()
  def float(opts \\ []), do: value_with_type(:float, opts)

  @doc """
  Represents a number.

  ## Options

  - `min` - the minimum acceptable value (included)
  - `max` - the maximum acceptable value (included)
  - `in` - a list of acceptable values
  - `between` - a `[min, max]` range of acceptable values

  Other options are detailed in [Common options](#module-common-options).

  ## Examples

      iex> Validator.validate(3.33, number())
      []

      iex> Validator.validate(3, number())
      []

      iex> Validator.validate("three", number())
      [%Validator.Error{context: [], message: "Expected type: number, got: \\"three\\"."}]

      iex> Validator.validate(-3.33, number(min: 0.0, max: 5.0))
      [%Validator.Error{context: [], message: "Must be greater than or equal to 0.0."}]

  """
  @spec number(keyword) :: Validator.Spec.t()
  def number(opts \\ []), do: value_with_type(:number, opts)

  @doc """
  Represents a boolean.

  ## Options

  - `in` - a list of acceptable values

  Other options are detailed in [Common options](#module-common-options).

  ## Examples

      iex> Validator.validate(true, boolean())
      []

      iex> Validator.validate("false", boolean())
      [%Validator.Error{context: [], message: "Expected type: boolean, got: \\"false\\"."}]

  """
  @spec boolean(keyword) :: Validator.Spec.t()
  def boolean(opts \\ []), do: value_with_type(:boolean, opts)

  @doc """
  Represents an atom.

  ## Options

  - `in` - a list of acceptable values

  Other options are detailed in [Common options](#module-common-options).

  ## Examples

      iex> Validator.validate(:timeout, atom())
      []

      iex> Validator.validate({:ok}, atom())
      [%Validator.Error{context: [], message: "Expected type: atom, got: {:ok}."}]

      iex> Validator.validate(:timeout, atom(in: [:ok, :error]))
      [%Validator.Error{context: [], message: "Invalid value: :timeout. Valid options: [:ok, :error]"}]

  """
  @spec atom(keyword) :: Validator.Spec.t()
  def atom(opts \\ []), do: value_with_type(:atom, opts)

  @doc """
  Represents a PID.

  ## Options

  - `in` - a list of acceptable values

  Other options are detailed in [Common options](#module-common-options).

  ## Examples

      iex> pid_value = IEx.Helpers.pid("0.106.1")
      #PID<0.106.1>
      iex> Validator.validate(pid_value, pid())
      []

      iex> Validator.validate("#PID<0.106.1>", pid())
      [%Validator.Error{context: [], message: "Expected type: pid, got: \\"#PID<0.106.1>\\"."}]

  """
  @spec pid(keyword) :: Validator.Spec.t()
  def pid(opts \\ []), do: value_with_type(:pid, opts)

  @doc """
  Represents a reference.

  ## Options

  - `in` - a list of acceptable values

  Other options are detailed in [Common options](#module-common-options).

  ## Examples

      iex> Validator.validate(make_ref(), ref())
      []

      iex> Validator.validate(33, ref())
      [%Validator.Error{context: [], message: "Expected type: ref, got: 33."}]

  """
  @spec ref(keyword) :: Validator.Spec.t()
  def ref(opts \\ []), do: value_with_type(:ref, opts)

  @doc """
  Represents a function.

  ## Options

  - `in` - a list of acceptable values
  - `arity` - the exact arity of the function

  Other options are detailed in [Common options](#module-common-options).

  ## Examples

      iex> Validator.validate(fn x -> x end, function())
      []

      iex> Validator.validate(&Enum.count/1, function(arity: 1))
      []

      iex> Validator.validate(%{}, function())
      [%Validator.Error{context: [], message: "Expected type: function, got: %{}."}]

      iex> Validator.validate(fn x, y -> x + y end, function(arity: 3))
      [%Validator.Error{context: [], message: "Expected arity of 3, found: 2."}]

  """
  @spec function(keyword) :: Validator.Spec.t()
  def function(opts \\ []), do: value_with_type(:function, opts)

  @doc """
  Represents a Port.

  ## Options

  - `in` - a list of acceptable values

  Other options are detailed in [Common options](#module-common-options).

  ## Examples

      iex> Validator.validate(Port.list() |> Enum.at(0), port())
      []

      iex> Validator.validate(123, port())
      [%Validator.Error{context: [], message: "Expected type: port, got: 123."}]

  """
  @spec port(keyword) :: Validator.Spec.t()
  def port(opts \\ []), do: value_with_type(:port, opts)

  @doc """
  A helper to define unexpected keys in maps.

  See [`map/2`](#map/2-non-specified-keys) to know how to use it.

  """
  @spec any_key :: Validator.AnyOtherKey.t()
  def any_key(), do: %AnyOtherKey{}

  @doc """
  A helper to define an optional key in maps.

  See [`map/2`](#map/2-optional-keys) to know how to use it.

  """
  @spec maybe(any) :: Validator.OptionalKey.t()
  def maybe(key), do: %OptionalKey{key: key}

  @doc """
  A helper to build other helpers for opaque structs.

  This function is used to define the [`time/1`](#time/1), [`datetime/1`](#datetime/1),
  [`naive_datetime/1`](#naive_datetime/1), and [`date/1`](#date/1) helpers.

  For example, this is how the [`date/1`](#date/1) function is implemented:

  ```elixir
  def date(opts \\\\ []) do
    Helpers.opaque_struct_type(
      Date,
      opts,
      converter: &cast_from/2,
      shortcut_rules: [
        after: &after_date/1,
        before: &before_date/1,
        between: &between_dates/2
      ]
    )
  end
  ```

  """
  @spec opaque_struct_type(atom, keyword, keyword) :: Validator.Spec.t()
  def opaque_struct_type(module, user_opts, opts \\ []) do
    converter = Keyword.get(opts, :converter, nil)
    shortcut_rules = Keyword.get(opts, :shortcut_rules, [])
    checks = built_in_checks(user_opts, shortcut_rules) ++ Keyword.get(user_opts, :checks, [])

    cast_from =
      user_opts
      |> Keyword.get(:cast_from, [])
      |> List.wrap()
      |> Enum.map(fn
        type when is_nil(converter) -> type
        {_, with: _converter} = type -> type
        type -> {type, with: &converter.(&1, type)}
      end)

    structure(module, Keyword.merge(user_opts, checks: checks, cast_from: cast_from))
  end

  @doc """
  Represents a DateTime struct.

  ## Options

  - `after` - the minimum acceptable datetime (included)
  - `before` - the maximum acceptable datetime (included)
  - `between` - a `[min, max]` range of acceptable datetimes

  Other options are detailed in [Common options](#module-common-options).

  ## Examples

      iex> Validator.validate(DateTime.utc_now(), datetime())
      []

      iex> Validator.validate("2015-01-23T23:50:07Z", datetime(cast_from: :string))
      []

      iex> Validator.validate(~U[2011-01-23 23:50:07Z], datetime(after: ~U[2015-01-23 23:50:07Z]))
      [%Validator.Error{context: [], message: "The datetime should be later than 2015-01-23 23:50:07Z."}]

      iex> Validator.validate(~N[2011-01-23 23:50:07], datetime())
      [%Validator.Error{context: [], message: "Expected struct of type: DateTime, got struct of type: NaiveDateTime."}]

  """
  defdelegate datetime(opts \\ []), to: Validator.Types.DateTime

  @doc """
  Represents a NaiveDateTime struct.

  ## Options

  - `after` - the minimum acceptable datetime (included)
  - `before` - the maximum acceptable datetime (included)
  - `between` - a `[min, max]` range of acceptable datetimes

  Other options are detailed in [Common options](#module-common-options).

  ## Examples

      iex> Validator.validate(NaiveDateTime.utc_now(), naive_datetime())
      []

      iex> Validator.validate("2015-01-23 23:50:07Z", naive_datetime(cast_from: :string))
      []

      iex> Validator.validate(~N[2011-01-23 23:50:07Z], naive_datetime(after: ~N[2015-01-23 23:50:07Z]))
      [%Validator.Error{context: [], message: "The naive datetime should be later than 2015-01-23 23:50:07."}]

      iex> Validator.validate(~U[2011-01-23T23:50:07Z], naive_datetime())
      [%Validator.Error{context: [], message: "Expected struct of type: NaiveDateTime, got struct of type: DateTime."}]

  """
  defdelegate naive_datetime(opts \\ []), to: Validator.Types.NaiveDateTime

  @doc """
  Represents a Date struct.

  ## Options

  - `after` - the minimum acceptable date (included)
  - `before` - the maximum acceptable date (included)
  - `between` - a `[min, max]` range of acceptable dates

  Other options are detailed in [Common options](#module-common-options).

  ## Examples

      iex> Validator.validate(Date.utc_today(), date())
      []

      iex> Validator.validate("2015-01-23", date(cast_from: :string))
      []

      iex> Validator.validate(~D[2011-01-23], date(after: ~D[2015-01-23]))
      [%Validator.Error{context: [], message: "The date should be later than 2015-01-23."}]

      iex> Validator.validate(~N[2011-01-23 23:50:07], date())
      [%Validator.Error{context: [], message: "Expected struct of type: Date, got struct of type: NaiveDateTime."}]

  """
  defdelegate date(opts \\ []), to: Validator.Types.Date

  @doc """
  Represents a Time struct.

  ## Options

  - `after` - the minimum acceptable time (included)
  - `before` - the maximum acceptable time (included)
  - `between` - a `[min, max]` range of acceptable times

  Other options are detailed in [Common options](#module-common-options).

  ## Examples

      iex> Validator.validate(Time.utc_now(), time())
      []

      iex> Validator.validate("23:50:07", time(cast_from: :string))
      []

      iex> Validator.validate(~T[21:15:00], time(after: ~T[23:50:07]))
      [%Validator.Error{context: [], message: "The time should be later than 23:50:07."}]

      iex> Validator.validate(~N[2011-01-23 23:50:07], time())
      [%Validator.Error{context: [], message: "Expected struct of type: Time, got struct of type: NaiveDateTime."}]

  """
  defdelegate time(opts \\ []), to: Validator.Types.Time

  #######################
  #   BUILT-IN CHECKS   #
  #######################

  defp built_in_checks(opts, rules) when is_list(rules) do
    rules
    |> Enum.reduce([], fn {key, rule}, acc ->
      case Keyword.fetch(opts, key) do
        {:ok, args} ->
          rule
          |> Function.info()
          |> Keyword.get(:arity, 1)
          |> case do
            0 when args == true -> [rule.() | acc]
            0 -> acc
            1 -> [rule.(args) | acc]
            _ -> [apply(rule, args) | acc]
          end

        :error ->
          acc
      end
    end)
    |> Enum.reverse()
  end

  defp built_in_checks(opts, :number) do
    opts
    |> built_in_checks(
      min: &Rule.min/1,
      max: &Rule.max/1,
      in: &Rule.one_of/1,
      between: &Rule.between/2
    )
  end

  defp built_in_checks(opts, :integer) do
    built_in_checks(opts, :number)
  end

  defp built_in_checks(opts, :float) do
    built_in_checks(opts, :number)
  end

  defp built_in_checks(opts, :string) do
    opts
    |> built_in_checks(
      min_length: &Rule.min_length/1,
      max_length: &Rule.max_length/1,
      length: &Rule.exact_length/1,
      in: &Rule.one_of/1,
      non_empty: &Rule.non_empty/0,
      format: &Rule.match/1
    )
  end

  defp built_in_checks(opts, :list) do
    opts
    |> built_in_checks(
      min_length: &Rule.min_length/1,
      max_length: &Rule.max_length/1,
      length: &Rule.exact_length/1,
      in: &Rule.one_of/1,
      non_empty: &Rule.non_empty/0,
      no_duplicate: &Rule.no_duplicate/0
    )
  end

  defp built_in_checks(opts, :function) do
    opts
    |> built_in_checks(
      in: &Rule.one_of/1,
      arity: &Rule.arity/1
    )
  end

  defp built_in_checks(opts, _) do
    opts
    |> built_in_checks(in: &Rule.one_of/1)
  end
end
