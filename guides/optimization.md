# Optimization

Flawless is not particularly slow, but it can be quite slower than other tools
by default. This page explains a few ways to mitigate that.

## Disable the schema validation

By default, the `validate/3` function will validate the schema before validating
the value. This can often take more time than validating the data. If you trust
your schema, you should disable that option with `check_schema: false`.

If you still wish to check the schema, it might be wiser to directly call
`validate_schema/1` at one place, and make sure that it isn't called everytime
you need to validate data with this schema.

## Build the schema only once

Flawless schemas are built using many helpers. While they are not that heavy,
making sure to build the schema only once and re-using it later can save a bit
more time.

## Use stop_early

If you do not need *all* the errors when validating, or just want to know
whether data is valid or not, you should use `stop_early: true`. This won't
improve the performance if the data is valid. But it can drastically improve it
when there is an error, as it will skip large parts of the validation.
