# Run with `mix run benchmark/benchmark.exs`

import Flawless.Helpers
import Norm

value = %{
  "name" => "",
  "hobbies" => ["yoyo", "computer", "singing", "", "a", "running"],
  "age" => 17,
  "hair_color" => "blonde"
}

flawless = fn ->
  schema = %{
    "name" => string(non_empty: true),
    "hobbies" => [string(min_length: 3)],
    maybe("age") => number(cast_from: :string)
  }

  Flawless.validate(value, schema)
end

schema_flawless_optimized = %{
  "name" => string(non_empty: true),
  "hobbies" => [string(min_length: 3)],
  maybe("age") => number()
}

flawless_optimized = fn ->
  Flawless.validate(value, schema_flawless_optimized, check_schema: false, group_errors: false)
end

flawless_optimized_stop_early = fn ->
  Flawless.validate(value, schema_flawless_optimized,
    check_schema: false,
    group_errors: false,
    stop_early: true
  )
end

skooma = fn ->
  schema = %{
    "name" => [:string, Skooma.Validators.min_length(1)],
    "hobbies" => [:list, [:string, Skooma.Validators.min_length(3)]],
    "age" => [:number, :not_required]
  }

  Skooma.valid?(value, schema)
end

norm_schema =
  schema(%{
    "name" => spec(is_binary() and (&(&1 != ""))),
    "hobbies" => coll_of(spec(is_binary() and (&(String.length(&1) >= 3)))),
    "age" => spec(is_number())
  })

final_schema = selection(norm_schema, ["name", "age"])

norm = fn ->
  try do
    conform!(value, final_schema)
  rescue
    _ -> nil
  end
end

Benchee.run(%{
  "flawless" => flawless,
  "flawless_optimized" => flawless_optimized,
  "flawless_optimized_stop_early" => flawless_optimized_stop_early,
  "skooma" => skooma,
  "norm" => norm
})
