# Validator

Validator is an Elixir library to help validate user input against a schema.


```elixir
iex> import Validator.Helpers

iex> schema = %{
...>   "username" => string(max_length: 30),
...>   "address" => %{
...>     "street" => string(),
...>     "number" => integer(min: 0, cast_from: :string),
...>     "city" => string(),
...>   },
...>   maybe("interests") => list(string(), min_length: 1)
...> }

iex> value = %{
...>   "address" => %{
...>     "country" => "Belgium",
...>     "number" => "10",
...>     "street" => "Main street",
...>     "city" => "Brussels"
...>   },
...>   "interests" => ["programming", "music", :games]
...> }

iex> Validator.validate(value, schema)
[
  %Validator.Error{
    context: [],
    message: "Missing required fields: \"username\" (string)."
  },
  %Validator.Error{
    context: ["address"],
    message: "Unexpected fields: [\"country\"]."
  },
  %Validator.Error{
    context: ["interests", 2],
    message: "Expected type: string, got: :games."
  }
]
```

## Why another validation library?

There are already a lot of validation libraries in Elixir. So why write another
one?

When I looked for other libraries, I found that there were a few recurrent
issues. Namely, poor error messages (not very suitable for user-facing
applications), and a cumbersome or inconsistent syntax. While they all have
their qualities, I wanted to try out something that was more to my taste.

As much as possible, this library tries to be:

- **Consistent:** all the helpers provide the same set of common options.
- **General:** some validation rules might be harder to define than others, but
  it avoids imposing any restriction.
- **Readable:** a lot of helpers and shortcuts are provided to make the schemas
  as simple as possible. The syntax is similar to the syntax of typespecs (when
  it makes sense) and should feel natural if you're used to it.
- **User-friendly:** useful errors are returned with clear messages and context,
  so that it should be easy for a user to understand how to fix the input.
- **Modular:** schemas are normal Elixir objects and can be easily combined
  together. No restricting syntax or macro is imposed.

## Schema definition

This section is only an overview. For details, see the dedicated
[Schema definition](guides/schema_definition.md) page.

### Helpers

Schemas are built using helper functions, that internally create more complex
structures used during validation. Every data type (string, number, map, list,
etc.) has its own helper function.

All helpers support a few common options:

- `checks` / `check` - See [Checks](#checks)
- `late_checks` / `late_check` - See [Checks](#checks)
- `nil` - See [Nullable values](#nullable-values)
- `cast_from` - See [Casting](#casting)

The `value()` helper is the only helper without a specific type. It can be used
to match literally anything.

### Checks

Every element can define a series of checks. Each check will evaluate a predicate
on the value and return an error message if it didn't pass. A few built-in rules
are available in `Validator.Rule` though shortcuts are also available for them.

It is also possible to define your own rules easily using the `rule/2` helper or
a simple function that returns an `:ok`/`:error` tuple. For more information, see
the [Custom checks](guides/custom_checks.md) page.

Late checks allow to evaluate rules *after all other checks have passed*. This
is useful if the rule should only be evaluated on well-formed data.

```elixir
# An integer between 0 and 10
integer(checks: [between(0, 10)])

# Accepts only "yes", true, or 1
value(check: one_of(["yes", true, 1]))

# A number that is different from 0
number(check: rule(&(&1 != 0), "The number should be different from zero."))

# The late check never fails because we're sure keys a and b exist
map(
  %{a: number(), b: number()},
  late_check: rule(fn x -> x.a > x.b end, "a must be bigger than b.")
)
```

### Primitive types

Validator supports all primitive Elixir types with the functions `integer/1`,
`float/1`, `number/1`, `string/1`, `boolean/1`, `atom/1`, `pid/1`, `ref/1`,
`function/1` and `port/1`. Each of them supports specific options, which are
shortcuts to avoid lengthy `checks`.

```elixir
# A non-empty string
string(non_empty: true)

# An integer between 0 and 100
integer(min: 0, max: 100)
```

### Nullable values

Every element supports the `nil` boolean option. When it is `true`, the element
can be `nil` even if that doesn't match any of the other constraints.

It is `false` by default, except for optional keys in maps.

### Maps

Maps are defined using `map/2` or directly with a map if no options are
necessary. By default, all keys are *required*, but optional keys can be defined
with the `maybe/1` helper. Non-specified keys are by default forbidden, but it
can be changed by adding the `any_key()` key in the map.

```elixir
map(
  %{
    # Define two required keys
    "id" => integer(),
    "name" => string(),

    # Define one optional field
    maybe("age") => integer(),

    # Accept any other key as long as the values are strings
    any_key() => string()
  },
  nil: false
)

# If we drop the `nil` option, we can ignore the `map()` function
%{
  "id" => integer(),
  "name" => string(),
  maybe("age") => integer(),
  any_key() => string()
}
```

### Structs

Structs work similarly to map but with the `structure/2` helper:

```elixir
structure(
  %Profile{id: integer(), username: string(), created_at: datetime()}
)

# Or just
%Profile{id: integer(), username: string(), created_at: datetime()}
```

Opaque structs can be checked by specifying only the module:

```elixir
structure(Profile)
```

### Lists

Lists are validated by providing a schema that every item must conform to:

```elixir
# A list of strings with at least two elements
list(string(), min_length: 2)

# A list of numbers (shortcut)
[number()]
```

### Tuples

Tuples are validated by providing a schema for each element:

```elixir
# A two-element tuple with an atom and a string
tuple({atom(), string()})

# A three-element tuple with three floats (shortcut)
{float(), float(), float()}
```

### Literals

Literal values (constants) are validated using the `literal/2` helper
or the value itself for numbers, atoms and strings:

```elixir
# Match the list `[1, 2, 3]`
literal([1, 2, 3])

# Match an {:ok, string} tuple (two alternatives)
{literal(:ok), string()}
{:ok, string()}
```

### Date & Time

Elixir has 4 built-in structs for date and time. They can be checked with the
`date()`, `time()`, `datetime()` and `naive_datetime()` helpers:

```elixir
# A DateTime before 1 January 2012 at 12:00:00
datetime(before: ~U[2012-01-01 12:00:00Z])

# A Time after 08:00
time(after: ~T[08:00:00])
```

### Recursive schemas

Recursive schemas can be defined by providing 0-arity functions:

```elixir
def tree_schema do
  %{
    value: number(),
    children: list(&tree_schema/0)
  }
end
```

### Unions

Unions can be defined using 1-arity functions that decide which schema
to use based on the input data:

```elixir
%{
  # Metadata is either a map with string values, or a list of strings
  "metadata" => fn
    %{} -> map(%{any_key() => string()})
    [_ | _] -> list(string())
  end
}
```

### Casting

Data can be automatically casted to the expected type if possible. The data is
validated after the casting has been performed:

```elixir
# Accept positive numbers, or strings representing positive numbers
number(cast_from: :string, min: 0)

# With a custom converter
map(%{"value" => number()}, cast_from: {:string, with: &Jason.decode/2})
```

## Validate data

You can validate data against a schema with the `validate/3` function. It 
returns a list of errors, which is empty if the data is valid.

```elixir
iex> schema = %{name: string(), age: number()}

iex> validate(%{name: :Colin}, schema)
[
  %Validator.Error{context: [], message: "Missing required fields: :age (number)."},
  %Validator.Error{context: [:name], message: "Expected type: string, got: :Colin."}
]

iex> validate(%{name: "Colin", age: 26}, schema)
[]
```

## Validate schemas

You can validate that a schema you're using is a valid schema with the
`validate_schema/1` function:

```elixir
schema = %{
  name: string(),
  age: number()
}

validate_schema(schema)
```

It returns the same kind of errors as `validate/3`. The "schema of a schema" is
actually defined using this library, and that schema validates itself.

By default, validating a value against a schema will validate the schema first.
If you wish to disable that behaviour (in particular if you can the function
many times with the same schema), set the `check_schema` option to false.

## Not what you need?

If you find a bug, or if you would like to propose improvements, please open an
issue or submit a PR.

If this library does not fit exactly your needs, check out those other validation
libraries. One of them might be best suited to your use case or preferences:

- [Vex](https://github.com/CargoSense/vex)
- [Norm](https://github.com/elixir-toniq/norm)
- [Skooma](https://github.com/bobfp/skooma)
- [Xema](https://github.com/hrzndhrn/xema)
- [ex_json_schema](https://github.com/jonasschmidt/ex_json_schema)
- [Exop](https://github.com/madeinussr/exop)
- [Joi](https://github.com/scottming/joi)
- [Optimal](https://hexdocs.pm/optimal/readme.html)
- [TypeCheck](https://github.com/Qqwy/elixir-type_check)

## License

The source code of Validator is licensed under the MIT License.
