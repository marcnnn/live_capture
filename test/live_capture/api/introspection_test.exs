defmodule LiveCapture.API.IntrospectionTest do
  use ExUnit.Case, async: true

  alias LiveCapture.API.Introspection
  alias LiveCapture.Component.Components.Example

  describe "get_all/1" do
    test "returns captures structure with component loaders" do
      result = Introspection.get_all([LiveCapture.LiveCaptureDemo])

      assert %{captures: captures} = result
      assert is_list(captures)
      assert length(captures) > 0
    end

    test "returns empty captures for empty loaders" do
      result = Introspection.get_all([])

      assert %{captures: []} = result
    end

    test "includes the Example module" do
      result = Introspection.get_all([LiveCapture.LiveCaptureDemo])

      example_capture =
        Enum.find(result.captures, fn c ->
          c.module == "Elixir.LiveCapture.Component.Components.Example"
        end)

      assert example_capture != nil
      assert example_capture.module_short_name == "Example"
    end
  end

  describe "extract_module_metadata/1" do
    test "extracts module name and short name" do
      metadata = Introspection.extract_module_metadata(Example)

      assert metadata.module == "Elixir.LiveCapture.Component.Components.Example"
      assert metadata.module_short_name == "Example"
    end

    test "extracts all functions with captures" do
      metadata = Introspection.extract_module_metadata(Example)
      function_names = Enum.map(metadata.functions, & &1.name)

      assert "simple" in function_names
      assert "with_default" in function_names
      assert "with_capture_attributes" in function_names
      assert "with_capture_variants" in function_names
      assert "with_slots" in function_names
    end

    test "extracts variants from function" do
      metadata = Introspection.extract_module_metadata(Example)

      variant_function =
        Enum.find(metadata.functions, fn f -> f.name == "with_capture_variants" end)

      assert variant_function.variants == ["main", "secondary"]
    end

    test "returns empty variants for function without variants" do
      metadata = Introspection.extract_module_metadata(Example)

      simple_function = Enum.find(metadata.functions, fn f -> f.name == "simple" end)

      assert simple_function.variants == []
    end

    test "extracts default breakpoints from loader" do
      metadata = Introspection.extract_module_metadata(Example)

      simple_function = Enum.find(metadata.functions, fn f -> f.name == "simple" end)

      assert simple_function.breakpoints == ["s", "m", "l", "xl"]
    end

    test "extracts attributes in metadata" do
      metadata = Introspection.extract_module_metadata(Example)

      with_capture_attrs =
        Enum.find(metadata.functions, fn f -> f.name == "with_capture_attributes" end)

      assert with_capture_attrs.metadata["attributes"] == %{"title" => "Galaxy"}
    end

    test "sorts functions by name" do
      metadata = Introspection.extract_module_metadata(Example)
      function_names = Enum.map(metadata.functions, & &1.name)

      assert function_names == Enum.sort(function_names)
    end
  end
end
