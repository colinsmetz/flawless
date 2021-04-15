# Validator

This is a library to help validate JSON-like objects (in Elixir format) against
a specific schema.

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
* `required`: whether the element is required (false by default)
* `checks`: a list of rules that the element must pass

Example:

```elixir
value(required: true, checks: [is_string_type(), one_of(["csv", "ftp"])])
```

### Basic elements

Several helpers are provided to define basic elements:

* `value()`: matches anything
* `integer()`
* `float()`
* `number()`
* `string()`
* `boolean()`

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

### Rules

Several rules are predefined and can be used in `checks`:
* `one_of(list)`: checks that the value is among a predefined set of elements

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

## Improvements

* A field with a `nil` value is considered as present (the `required` constraint
  will pass), should it?
