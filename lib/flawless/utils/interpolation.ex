defmodule Flawless.Utils.Interpolation do
  @moduledoc """
  This module is simplification of the Gettext.Interpolation module in the gettext library.
  """

  @spec sigil_t(any, any) :: list(atom() | binary())
  defmacro sigil_t(term, modifiers \\ [])

  defmacro sigil_t({:<<>>, _meta, [string]}, _options) when is_binary(string) do
    template_parts(string)
  end

  @spec from_template(binary() | list(), Keyword.t()) :: binary()
  def from_template(parts, bindings) when is_list(parts) do
    interpolate([], parts, bindings)
  end

  def from_template(template, bindings) when is_binary(template) do
    parts = template_parts(template)
    interpolate([], parts, bindings)
  end

  defp template_parts(template) do
    template_parts(template, [])
  end

  defp template_parts(template, parts) do
    case :binary.split(template, "%{") do
      [rest] ->
        [rest | parts]

      [before, rest] ->
        parts = [before | parts]

        case :binary.split(rest, "}") do
          [_] -> [template | parts]
          [binding, rest] -> template_parts(rest, [String.to_existing_atom(binding) | parts])
        end
    end
  end

  defp interpolate(strings, template_parts, bindings)

  defp interpolate(strings, [], _bindings) do
    IO.iodata_to_binary(strings)
  end

  defp interpolate(strings, [string | parts], bindings) when is_binary(string) do
    interpolate([string | strings], parts, bindings)
  end

  defp interpolate(strings, [key | parts], bindings) when is_atom(key) do
    string = bindings |> Keyword.get(key, "<?>") |> to_string()
    interpolate([string | strings], parts, bindings)
  end
end
