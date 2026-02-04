defmodule Mix.Tasks.LiveCapture.Gen.Urls do
  @shortdoc "Generates a JSON file with capture URLs for testing"

  @moduledoc """
  Generates a JSON file containing URLs for all captured components.

  This is useful for automated visual regression testing with Playwright.

  ## Resources

    * [Playwright Visual Comparisons](https://playwright.dev/docs/test-snapshots)
    * [Playwright Dynamic Tests](https://github.com/microsoft/playwright/issues/7036)

  ## Usage

      mix live_capture.gen.urls --module MyAppWeb.LiveCapture --prefix /dev/storybook path/to/captures.json

  Multiple modules can be specified:

      mix live_capture.gen.urls --module MyAppWeb.LiveCapture --module MyAppWeb.AdminCapture --prefix /dev/storybook path/to/captures.json

  ## Options

    * `--module` (required) - The LiveCapture loader module(s). Can be specified multiple times.
    * `--prefix` - URL prefix where LiveCapture is mounted (default: "/")

  ## Output Format

  The generated JSON file contains an array of schema objects:

      [
        {
          "schema": "MyAppWeb.LiveCapture",
          "breakpoints": [
            {"name": "s", "width_px": 480},
            {"name": "m", "width_px": 768}
          ],
          "components": [
            {"module": "MyAppWeb.Example", "function": "button", "variant": null, "url": "/dev/storybook/raw/components/Example/button"},
            {"module": "MyAppWeb.Example", "function": "button", "variant": "primary", "url": "/dev/storybook/raw/components/Example/button/primary"}
          ]
        }
      ]
  """

  use Mix.Task

  alias LiveCapture.API.Introspection
  alias LiveCapture.Router

  @impl Mix.Task
  def run(args) do
    {opts, positional, _} =
      OptionParser.parse(args,
        strict: [module: :keep, prefix: :string],
        aliases: [m: :module, p: :prefix]
      )

    module_names = Keyword.get_values(opts, :module)
    prefix = opts[:prefix] || ""
    output_path = List.first(positional)

    with :ok <- validate_modules(module_names),
         :ok <- validate_output_path(output_path) do
      generate_urls(module_names, prefix, output_path)
    else
      {:error, message} ->
        Mix.shell().error(message)
        exit({:shutdown, 1})
    end
  end

  defp validate_modules([]) do
    {:error,
     "Missing required --module option. Usage: mix live_capture.gen.urls --module MyAppWeb.LiveCapture path/to/output.json"}
  end

  defp validate_modules(_modules), do: :ok

  defp validate_output_path(nil) do
    {:error,
     "Missing output path. Usage: mix live_capture.gen.urls --module MyAppWeb.LiveCapture path/to/output.json"}
  end

  defp validate_output_path(_path), do: :ok

  defp generate_urls(module_names, prefix, output_path) do
    Mix.Task.run("compile", [])
    Mix.Task.run("app.start", [])

    schemas =
      Enum.map(module_names, fn module_name ->
        build_schema(module_name, prefix)
      end)

    total_components = Enum.reduce(schemas, 0, fn s, acc -> acc + length(s.components) end)

    json = Jason.encode!(schemas, pretty: true)

    output_path
    |> Path.dirname()
    |> File.mkdir_p!()

    File.write!(output_path, json)

    Mix.shell().info("Generated #{total_components} capture URLs to #{output_path}")
  end

  defp build_schema(module_name, prefix) do
    loader = Module.concat([module_name])

    unless Code.ensure_loaded?(loader) do
      Mix.shell().error("Module #{module_name} could not be loaded")
      exit({:shutdown, 1})
    end

    data = Introspection.get_all([loader])
    breakpoints = get_breakpoints(loader)
    components = build_components(data.captures, prefix)

    %{
      schema: module_name,
      breakpoints: breakpoints,
      components: components
    }
  end

  defp get_breakpoints(loader) do
    if function_exported?(loader, :breakpoints, 0) do
      loader.breakpoints()
      |> Enum.map(fn {name, width} -> %{name: to_string(name), width_px: parse_pixels(width)} end)
    else
      []
    end
  end

  defp parse_pixels(value) when is_binary(value) do
    value |> String.replace(~r/[^\d]/, "") |> String.to_integer()
  end

  defp parse_pixels(value) when is_integer(value), do: value

  defp build_components(modules, prefix) do
    Enum.flat_map(modules, fn module_data ->
      Enum.flat_map(module_data.functions, fn function_data ->
        build_function_components(module_data, function_data, prefix)
      end)
    end)
  end

  defp build_function_components(module_data, function_data, prefix) do
    base = [build_component(module_data, function_data, nil, prefix)]

    variants =
      Enum.map(function_data.variants, fn variant ->
        build_component(module_data, function_data, variant, prefix)
      end)

    base ++ variants
  end

  defp build_component(module_data, function_data, variant, prefix) do
    url =
      Router.raw_component_url(
        prefix,
        module_data.module_short_name,
        function_data.name,
        variant
      )

    %{
      module: module_data.module,
      function: function_data.name,
      variant: variant,
      url: url
    }
  end
end
