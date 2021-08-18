# Validator

This is a library to help validate Elixir values against a specific schema.

Example:

```elixir
  map = %{
    "format" => "yml",
    "fields" => [
      %{"name" => "a", "type" => "INT64", "is_key" => true, "is_required" => false},
      %{"name" => "b", "type" => "STRING"}
    ],
    "polling" => %{
      "slice_size" => "50MB",
      "interval_seconds" => "12",
      "timeout_ms" => "34567"
    },
    "plop" => 14
  }

  schema = %{
    "format" => req_string(checks: [one_of(["csv", "xml"])]),
    "regex" => req_string(),
    "polling" =>
      map(%{
        "slice_size" => value()
      }),
    "fields" =>
      list(
        map(
          %{
            "name" => req_string(),
            "type" => req_string(),
            "is_key" => boolean(),
            "is_required" => boolean()
          },
          checks: [required_if_is_key()]
        ),
        checks: [rule(&length(&1) > 0, "Fields must contain at least one item")]
      )
  }

  Validator.validate(map, schema)
```

The `validate` call on the last line will return the list of errors found in the map:

```elixir
[
  %Validator.Error{context: [], message: "Unexpected fields: [\"plop\"]"},
  %Validator.Error{context: [], message: "Missing required fields: [\"regex\"]"},
  %Validator.Error{
    context: ["fields", 0],
    message: "Field 'a' is a key but is not required"
  },
  %Validator.Error{
    context: ["format"],
    message: "Invalid value 'yml'. Valid options: [\"csv\", \"xml\"]"
  },
  %Validator.Error{
    context: ["polling"],
    message: "Unexpected fields: [\"interval_seconds\", \"timeout_ms\"]"
  }
]
```

## How to use

All types of elements support a few common options:
* `required`: whether the element is required (false by default).
* `checks`: a list of rules that the element must pass.
* `check`: similar to `checks` but for a single rule; can be passed multiple
  times.
* `type`: the type of the element (`:any` by default).
* `cast_from`: a type or list of types, to cast the value to the expected type
  before validating, if necessary (see [Casting](#casting) section below).

Example:

```elixir
value(required: true, type: :string, checks: [one_of(["csv", "ftp"])])
```

### Basic elements

Several helpers are provided to define basic elements:

* `value()`: matches anything
* `integer()`
* `float()`
* `number()`
* `string()`
* `boolean()`
* `atom()`
* `pid()`

The type constraint will be added automatically to the `checks` when using
specific type elements.

Besides, to avoid repeating, `required: true`, a shortcut is provided
for each of them:

* `req_value()`
* `req_integer()`
* `req_float()`
* `req_number()`
* `req_string()`
* `req_boolean()`
* `req_atom()`
* `req_pid()`

### Maps

A map is defined using the `map(spec, opts)` and `req_map(spec, opts)`
helpers. The spec is a map representing the expected map, e.g.

```elixir
map(
  %{
    "first_name" => req_string(),
    "last_name" => req_string(),
    "age" => req_number()
  },
  checks: [
    first_name_different_than_last_name()
  ]
)
```

If you do not need to use the `required` or `checks` options, the `map()`
function can be entirely ignored:

```elixir
%{
  "first_name" => req_string(),
  "last_name" => req_string(),
  "age" => req_number()
}
```

#### Accept non-defined fields

By default, if the input map contains keys that were not defined in the schema,
it will return an error. To avoid that, you should make sure to define *all*
the potential keys that the map could have.

If you still want to accept other non-defined keys, you can use the `any_key()`
helper as a key in the map:

```elixir
%{
  "id" => req_string(),
  any_key() => string()
}
```

This will make sure that the map contains a field named `id`, but also accept
any other unexpected field in the map. Those extra fields should however comply
with the associated schema (which could be `value()` to truly accept anything).

### Lists

A list is defined using `list(item_spec, opts)` or `req_list(item_spec, opts)`.
The constraint of `item_spec` will be checked for every element in the list.
Example:

```elixir
# A list of strings, which must have at least 2 items
list(string(), checks: [min_length(2)])
```

If the `required` or `checks` options are not used, you can use the shortcut
`[spec]`:

```elixir
# A list of string
[string()]
```

### Tuples

A tuple is defined using `tuple(elem_specs, opts)` or `req_tuple(elem_specs, opts)`.
The `elem_specs` is a tuple of the expected tuple size, and each of element of the
tuple is the expected schema for the corresponding tuple element. Example:

```elixir
# A tuple of size 2, where the first element is an atom and the second one a string
# The entire tuple must conform to `custom_rule`.
tuple({atom(), string()}, checks: [custom_rule()])
```

If the `required` or `checks` options are not used, the `tuple()` function can be
entirely ignored:

```elixir
# A tuple of size 2, where the first element is an atom and the second one a string
{atom(), string()}
```

### Literals

If you need to match against a specific value, use `literal(value)`. It will
match only if the value is exactly the expected one.

The schema `literal(10)` would actually be equivalent to `integer(in: [10])`,
but it has the advantage of being more explicit and provide a better error
message.

### Rules

Several rules are predefined and can be used in `checks`:
* `one_of(list)`: checks that the value is among a predefined set of elements

The type helpers (`number()`, `req_string()`, etc.) also accept shortcut options
for their supported built-in rules. For example, those are equivalent:

```elixir
number(checks: [min(2), max(6)])
number(min: 2, max: 6)
```

#### Custom rules

To define a custom rule, you must use the `rule(predicate, error_message)` function:
* `predicate` is a function taking the value as argument, and returning a
  boolean (`true` if the condition is met).
* `error_message` defines the error message when the predicate didn't pass, and
  can be either:
  * A string, which is returned as such.
  * A function with one parameter (the value) and returning the error string.
  * A function with two parameters (the value and the context) and returning
    the error string. The context is the list of field names (or indices for
    lists) defining *where* the error is located.

Example:

```elixir
def max_length(n) do
  rule(
    fn value -> length(value) <= n end,
    fn value -> "The length is #{length(value)}, but the maximum is #{n}" end
  )
end
```

### Casting

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

### Recursive data structures

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

### Union types / Case type

Union types are supported as such. However, there are multiple ways a field can
have different types (without matching *anything* with `value()`):
* Using `cast_from` (see "Casting" section above).
* Using selectors

Selectors are defined using a 1-arity function taking the current data as a
parameter. This data can be used to decide on which schema should be used. For
example:

```elixir
schema = %{
  a: fn
    %{} -> %{b: number(), c: number()}
    l when is_list(l) -> list(number())
  end
}
```

This schema would accept field `:a` to be either:
* A map with schema `%{b: number(), c: number()}`
* A list of numbers

If the input data is not a map or a list, then it is considered an error and
none of the subschemas is tested.

Compared to a potential generic `union([typeA, typeB])` function, this method
has the advantage that we know which schema is expected to be used, so we can
return more specific errors corresponding to the selected subschemas. If we
didn't know, we'd have to either return a single generic error, or the errors
for both schemas, which would be confusing.

## Improvements

* A field with a `nil` value is considered as present (the `required` constraint
  will pass), should it?
