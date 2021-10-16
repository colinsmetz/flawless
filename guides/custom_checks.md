# Custom checks

There are two ways to create a custom rule:
* Using the `rule(predicate, error_message)` helper
* Using a simple 1-arity predicate function

The `predicate` in `rule/2` or the simple function follow the same rules:
* It must take exactly one argument, the data to validate.
* The data is considered valid if the function returns `true`, `:ok`, or a `{:ok, _}` tuple.
* The data is considered invalid if the function returns `false`, `:error`, or a `{:error, error}` tuple.

In case of error, the error message is evaluated like this:
* If `{:error, error}` was returned, `error` becomes the error message.
* If `error_message` is `nil` or the simple function was used, a generic message
  "The predicate failed." is returned.
* Otherwise `error_message` is evaluated and returned.

The `error_message` can be one of those:
* A string, which is returned as such.
* A `{template, opts}` tuple. The template is a string and opts is a keyword list.
  The interpolated variables will be replaced using values in the keyword list. This
  is not useful yet, but will be used for translation later.
* A function with one parameter (the value) and returning the error string or
  template tuple.
* A function with two parameters (the value and the context) and returning
  the error string or template tuple. The context is the list of field names
  (or indices for lists) defining *where* the error is located.

Note: error messages are automatically encapsulated to a `Validator.Error` struct.

Example:

```elixir
def max_length(n) do
  rule(
    fn value -> length(value) <= n end,
    fn value -> {"The length is %{length}, but the maximum is %{max}", length: length(value), max: n} end
  )
end

def is_lowercase(data) do
  if String.downcase(data) == data do
    :ok
  else
    {:error, "string must be in lowercase"}
  end
end

# ---

schema = string(checks: [max_length(5), &is_lowercase/1])
```
