# Schema definition

All types of elements support a few common options:
* `nil`: whether the element is nullable (default to `false` except for optional
  fields in maps).
* `checks`: a list of rules that the element must pass.
* `check`: similar to `checks` but for a single rule; can be passed multiple
  times.
* `late_checks`: similar to `checks`, but evaluated only if all other checks
  passed for the element.
* `late_check`: similar to `late_checks` but for a single rule; can be passed
  multiple times.
* `cast_from`: a type or list of types, to cast the value to the expected type
  before validating, if necessary (see [Casting](#casting) section below).
* `on_error`: an error message that will be used if the element is invalid, and
  override all the errors.
* `type`: the type of the element (`:any` by default). Usually not set directly,
  use the specific type helpers.


## Basic elements

Several helpers are provided to define basic types:

* `any()`
* `integer()`
* `float()`
* `number()`
* `string()`
* `boolean()`
* `atom()`
* `pid()`
* `ref()`
* `function()`
* `port()`

The following Elixir structs also have helpers:

* `datetime()` ([DateTime](https://hexdocs.pm/elixir/DateTime.html))
* `naive_datetime()` ([NaiveDateTime](https://hexdocs.pm/elixir/NaiveDateTime.html))
* `date()` ([Date](https://hexdocs.pm/elixir/Date.html))
* `time()` ([Time](https://hexdocs.pm/elixir/Time.html))

## Maps

A map is defined using the `map(schema, opts)` helper. The schema is a map
representing the expected map, e.g.

```elixir
map(
  %{
    "first_name" => string(),
    "last_name" => string(),
    "age" => number()
  },
  checks: [
    first_name_different_than_last_name()
  ]
)
```

If you do not need additional options like `checks`, the `map()` function can be
entirely ignored:

```elixir
%{
  "first_name" => string(),
  "last_name" => string(),
  "age" => number()
}
```

### Optional fields

By default, all keys defined in the maps are required. If you wish to define
optional keys, use the `maybe` helper around the optional key name:

```elixir
%{
  "name" => string(),
  "age" => number(),
  maybe("phone_number") => string(format: ~r/[0-9]+/)
}
```

**Note:** unless `nil` is explicitly set to `false`, the optional key is
considered to be nillable.

### Accept non-defined fields

By default, if the input map contains keys that were not defined in the schema,
it will return an error. To avoid that, you should make sure to define *all*
the potential keys that the map could have.

If you want to accept other non-defined keys, you can use the `any_key()` helper
as a key in the map:

```elixir
%{
  "id" => string(),
  any_key() => string()
}
```

This will make sure that the map contains a field named `id`, but also accept
any other unexpected key in the map. Those extra fields should however comply
with the associated schema (`string()` in this case).

## Structs

Structs function similarly to maps, with the `structure(spec, opts)` helper
(unfortunately `struct` is already a function in `Kernel`).

```elixir
structure(
  %User{
    first_name: string(),
    last_name: string(),
    age: number()
  },
  checks: [
    first_name_different_than_last_name()
  ]
)
```

Again, the `structure` function can be entirely omitted if options are not
necessary.

**Note:** a struct will never match a classic `map` schema, unless you specify
otherwise with the `cast_from: :struct` option.

### Opaque structs

If you don't know the internal fields of the struct, or only care about matching
the struct type, you can pass only the module:

```elixir
validate(DateTime.utc_now(), structure(DateTime))
# Result: []
```

## Lists

A list is defined using `list(item_spec, opts)`. The constraint of `item_spec`
will be checked for every element in the list. Example:

```elixir
# A list of strings, which must have at least 2 items
list(string(), checks: [min_length(2)])
```

If you do not need additional options like `checks`, you can use the shortcut
`[spec]`:

```elixir
# A list of string
[string()]
```

## Tuples

A tuple is defined using `tuple(elem_specs, opts)`. The `elem_specs` is a tuple
of the expected tuple size, and each of element of the tuple is the expected
schema for the corresponding tuple element. Example:

```elixir
# A tuple of size 2, where the first element is an atom and the second one a string
# The entire tuple must conform to `custom_rule`.
tuple({atom(), string()}, checks: [custom_rule()])
```

If you do not need additional options like `checks`, the `tuple()` function can be
entirely ignored:

```elixir
# A tuple of size 2, where the first element is an atom and the second one a string
{atom(), string()}
```

## Literals

If you need to match against a specific value, use `literal(value)`. It will
match only if the value is exactly the expected one.

The schema `literal(10)` would actually be equivalent to `integer(in: [10])`,
but it has the advantage of being more explicit and provide a better error
message.

For strings, atoms and numbers, the `literal()` function can even be ignored.
For example, those two schemas would be equivalent:

```elixir
schema1 = %{
  "a" => literal(88),
  "b" => literal(:ok),
  "c" => literal("hello")
}

schema2 = %{
  "a" => 88,
  "b" => :ok,
  "c" => "hello"
}
```

## Checks

### Late checks

Late checks are defined with `late_checks` or `late_check`. Those rules are
evaluated *only if the element is otherwise valid*, i.e., if the `checks` passed
and the sub-schemas were valid (in case of lists, maps, tuples, etc.).

This is useful if you have rules that make sense only if some preconditions are met.
Let's say you have a map with a few number fields, and you'd like to make sure that
the sum of all values is lower than some threshold. You could do:

```elixir
sum_lower_than_threshold = rule(
  fn map -> map["math_credits"] + map["english_credits"] < 15 end,
  "The sum of credits must be lower than 15." 
)

schema = map(
  %{"math_credits" => number(), "english_credits" => number()},
  check: sum_lower_than_threshold
)
```

If a well-formed input is passed, this is fine. But let's say it is not:

```elixir
value = %{"math" => 17}
validate(value, schema)

# Result:
[
  %Flawless.Error{
    context: [],
    message: "An exception was raised while evaluating a rule on that element, so it is likely incorrect."
  },
  # ...
]
```

The `sum_lower_than_threshold` was evaluated, but since the fields do not exist,
it resulted in an exception and a generic error message. If you replace `check` by
`late_check`, you can make sure the rule will be evaluated only when the input is
sufficiently well-formed.

### Built-in rules

Several rules are predefined and can be used in `checks`. Those are available in
the [Flawless.Rule](Flawless.Rule.html) module.

The type helpers (`number()`, `string()`, etc.) also accept shortcut options for
their supported built-in rules. You can find them in the
[`Flawless.Helpers`](Flawless.Helpers.html) documentation. For example, those
are equivalent:

```elixir
number(checks: [min(2), max(6)])
number(min: 2, max: 6)
```

### Custom rules

It is easy to define your own rules using `rule/2` or simple functions.

For more information, see [Custom checks](custom_checks.md).

## Casting

Let's say you have a schema like this:

```elixir
%{
  "code" => number(),
  "coordinates" => {float(), float(), integer()}
}
```

Now, you receive a value to validate against this schema. This value comes from
an external client where the `code` is a string input, and since it uses JSON,
tuples are replaced by arrays. Also, coordinates use only integers instead of
floats:

```elixir
%{
  "code" => "32",
  "coordinates" => [17, 17, 3]
}
```

One could decide to replace the schema with:

```elixir
%{
  "code" => string(),
  "coordinates" => [number()]
}
```

However, if another source of data was correctly matching the first schema, now it
doesn't, and we need to maintain two similar schemas and choose the correct one
manually. Besides, this new schema is too permissive: `code` does not necessarily
represent a number, and coordinates can have more than 3 elements. Additional
checks would be needed to validate that, but it would be cumbersome.

Instead, you can use the `cast_from` option for every part of your schema. It
indicates that the value might be of a different type than the expected one, but
should be cast automatically if possible. Using it, we could replace our initial
schema with:

```elixir
%{
  "code" => number(cast_from: :string),
  "coordinates" => tuple(
    {float(cast_from: :integer), float(cast_from: :integer), integer()},
    cast_from: :list
  )
}
```

Now our value would match the schema, while the schema remains precise.

Note that any additional check will be performed on the *converted* value.

### Use a custom converter

If the built-in conversions do not match your need, you can provide a custom converter.
It should return `{:ok, converted_value}` on success, and `:error` or `{:error, _}` otherwise.

Example:

```elixir
schema = map(
  %{"value" => number()},
  cast_from: {:string, with: &Jason.decode/2}
)

validate(~s({"value": 17}), schema)
# OK
```

## Recursive data structures

For recursive data structures, you can use 0-arity functions that return a
schema, like this:

```elixir
def tree_schema() do
  %{
    value: number(max: 100),
    left: &tree_schema/0,
    right: &tree_schema/0
  }
end
```

Then you can call `validate(tree, tree_schema())` as usual.

## Unions

Sometimes, a value can take multiple possible forms. In this case, it is useful
to specify a union of possible types. This possible to some extent using the
catch-all helper `any()` or using `cast_from`, but those are not exactly
unions.

Flawless offers two better ways to do unions of specific schemas.

### The `union` helper

The `union/1` helper takes a list of accepted schemas. A value is valid if it
matches any of the schemas. If none of them matches, errors are returned
according to the following rules:

* If the value matches the primary type of a single schema (not more than one),
  then the errors for that schema are returned.
* Otherwise, a generic error message is returned, listing the potential types.

The idea is to provide more specific error messages when it is very likely that
the user was aiming for one of the schemas in particular.

```elixir
iex> Flawless.validate("hello", union([string(), atom()]))
[]

iex> Flawless.validate(:hello, union([string(), atom()]))
[]

iex> Flawless.validate(15, union([string(), atom()]))
[%Flawless.Error{context: [], message: "The value does not match any schema in the union. Possible types: [:string, :atom]."}]

iex> Flawless.validate(15, union([number(max: 10), string()]))
[%Flawless.Error{context: [], message: "Must be less than or equal to 10."}]
```

### Pattern matching on the value

The `union` helper is handy but it often fails to provide specific error messages
as there is no way to choose between the schemas in the union most of the time.
An alternative could be to return the errors for *all possible schemas*, but this
would likely be confusing.

To solve that problem, you can define unions using 1-arity functions. The function
will receive the value as input, so that you can pattern match on it, and select
a schema.

```elixir
schema = fn
  %{type: "car"} ->
    %{
      type: string(),
      fuel_type: string(),
      model: string()
    }

  %{type: "bike"} ->
    %{
      type: string(),
      electric: boolean(),
      brake_type: string()
    }
end
```

This schema would accept either one map or the other depending on the value for
`:type`. If the value doesn't match any of the definitions, a generic error
message in returned.

## Replace errors with `on_error` option

It is possible to define a single error message to any element using the
`on_error` keyword. If the element emits errors during validation, they will be
discarded and replaced by this single error message.

This is useful for outputting more user-friendly error messages or limiting the
number of errors on a single element. For example:

```elixir
iex> value = "xX-DarkL0rd-Xx"
iex> schema1 = string(format: ~r/^[a-zA-Z_]+$/)
iex> validate(value, schema1)
[
  %Flawless.Error{
    context: [],
    message: "Value \"xX-DarkL0rd-Xx\" does not match regex ~r/^[a-zA-Z_]+$/."
  }
]

iex> schema2 = string(format: ~r/^[a-zA-Z_]+$/, on_error: "The username should only contain letters or underscores.")
iex> validate(value, schema2)
[
  %Flawless.Error{
    context: [],
    message: "The username should only contain letters or underscores."
  }
]
```
