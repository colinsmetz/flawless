# Validator

This is a library to help validate JSON-like objects (in Elixir format) against
a specific schema.

Example:

```elixir
  map = %{
    "format" => "yml",
    "regex" => "/the/regex",
    "fields" => [
      %{"name" => "a", "type" => "INT64", "is_key" => true, "is_required" => false},
      %{"name" => "b", "type" => "STRING", "tru" => "blop", "meta" => %{}}
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
