defmodule LiveCapture.API.Introspection do
  @moduledoc """
  Extracts capture metadata from registered modules for the JSON API.

  This module provides functions to introspect all captured components and
  return their metadata in a structured format suitable for JSON serialization.
  """

  alias LiveCapture.Component

  @doc """
  Returns capture metadata for all modules registered with the given component loaders.

  ## Example Response Structure

      %{
        captures: [
          %{
            module: "Elixir.MyApp.Components.Core",
            module_short_name: "Core",
            functions: [
              %{
                name: "button",
                variants: ["main", "secondary"],
                breakpoints: ["s", "m", "l", "xl"],
                metadata: %{attributes: %{...}}
              }
            ]
          }
        ]
      }
  """
  @spec get_all(list()) :: %{captures: list(map())}
  def get_all(component_loaders) do
    captures =
      component_loaders
      |> Component.list()
      |> Enum.map(&extract_module_metadata/1)
      |> Enum.sort_by(& &1.module_short_name)

    %{captures: captures}
  end

  @doc """
  Extracts metadata for a single module.
  """
  @spec extract_module_metadata(module()) :: map()
  def extract_module_metadata(module) do
    live_capture = module.__live_capture__()
    loader = live_capture[:loader]
    breakpoints = get_breakpoints(loader)

    functions =
      live_capture[:captures]
      |> Enum.map(fn {function_name, capture_config} ->
        extract_function_metadata(function_name, capture_config, breakpoints)
      end)
      |> Enum.sort_by(& &1.name)

    %{
      module: to_string(module),
      module_short_name: extract_short_name(module),
      functions: functions
    }
  end

  defp extract_function_metadata(function_name, capture_config, default_breakpoints) do
    variants = extract_variants(capture_config)
    breakpoints = extract_breakpoints(capture_config, default_breakpoints)

    metadata =
      capture_config
      |> Map.drop([:variants])
      |> Map.new(fn {k, v} -> {to_string(k), safe_serialize(v)} end)

    %{
      name: to_string(function_name),
      variants: variants,
      breakpoints: breakpoints,
      metadata: metadata
    }
  end

  defp extract_variants(capture_config) do
    case Map.get(capture_config, :variants) do
      nil -> []
      variants when is_list(variants) -> Keyword.keys(variants) |> Enum.map(&to_string/1)
      _ -> []
    end
  end

  defp extract_breakpoints(capture_config, default_breakpoints) do
    case Map.get(capture_config, :breakpoints) do
      nil -> default_breakpoints
      breakpoints when is_list(breakpoints) -> Enum.map(breakpoints, &to_string/1)
      _ -> default_breakpoints
    end
  end

  defp get_breakpoints(loader) when is_atom(loader) do
    if function_exported?(loader, :breakpoints, 0) do
      loader.breakpoints()
      |> Keyword.keys()
      |> Enum.map(&to_string/1)
    else
      []
    end
  rescue
    _ -> []
  end

  defp get_breakpoints(_), do: []

  defp extract_short_name(module) do
    module
    |> to_string()
    |> String.split(".")
    |> List.last()
  end

  # Safely serialize values for JSON - converts non-serializable values to strings
  defp safe_serialize(value) when is_function(value), do: "#Function"
  defp safe_serialize(value) when is_pid(value), do: inspect(value)
  defp safe_serialize(value) when is_reference(value), do: inspect(value)
  defp safe_serialize(value) when is_port(value), do: inspect(value)
  defp safe_serialize(%{__struct__: _} = struct), do: Map.from_struct(struct) |> safe_serialize()

  defp safe_serialize(value) when is_map(value) do
    Map.new(value, fn {k, v} -> {to_string(k), safe_serialize(v)} end)
  end

  defp safe_serialize(value) when is_list(value) do
    Enum.map(value, &safe_serialize/1)
  end

  defp safe_serialize(value) when is_tuple(value) do
    value |> Tuple.to_list() |> safe_serialize()
  end

  defp safe_serialize(value) when is_atom(value), do: to_string(value)
  defp safe_serialize(value), do: value
end
