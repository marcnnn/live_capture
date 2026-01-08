defmodule LiveCapture.Component do
  defmacro __using__(_) do
    quote do
      Module.register_attribute(__MODULE__, :capture, accumulate: true)
      Module.put_attribute(__MODULE__, :__captures__, %{})

      @on_definition LiveCapture.Component
      @before_compile LiveCapture.Component

      import LiveCapture.Component, only: [capture: 0, capture: 1, capture_all: 0]
    end
  end

  defmacro capture(attrs \\ []) do
    quote do
      Module.put_attribute(
        __MODULE__,
        :capture,
        Map.new(unquote(attrs))
      )
    end
  end

  defmacro capture_all() do
    quote do
      Module.put_attribute(
        __MODULE__,
        :capture_all,
        true
      )
    end
  end

  defmacro __before_compile__(_) do
    quote do
      def __captures__ do
        @__captures__
      end
    end
  end

  def __on_definition__(env, _kind, name, args, _guards, _body) do
    capture = env.module |> Module.delete_attribute(:capture) |> List.first()

    capture_all = Module.get_attribute(env.module, :capture_all) && length(args) == 1

    if capture || capture_all do
      captures =
        Module.get_attribute(env.module, :__captures__)
        |> Map.update(name, capture || %{}, fn value -> Map.merge(value, capture || %{}) end)

      Module.put_attribute(env.module, :__captures__, captures)
    end
  end

  def slot_names(module, function) do
    module.__components__()
    |> Map.get(function, %{})
    |> Map.get(:slots, [])
    |> Enum.map(& &1.name)
  end

  def render(env, module, function, variant \\ nil) do
    attributes = attributes(module, function, variant)

    slot_keys = slot_names(module, function)

    normalize_slot = fn slot_key, slot_value ->
      slot_value
      |> Map.put(:__slot__, slot_key)
      |> Map.replace(:inner_block, fn _, _ -> slot_value.inner_block end)
    end

    attributes =
      Enum.reduce(attributes, %{}, fn {key, value}, acc ->
        if Enum.member?(slot_keys, key) do
          slot =
            cond do
              is_map(value) -> normalize_slot.(key, value)
              is_list(value) -> Enum.map(value, &normalize_slot.(key, &1))
              true -> normalize_slot.(key, %{inner_block: value})
            end

          Map.put(acc, key, slot)
        else
          Map.put(acc, key, value)
        end
      end)

    Phoenix.LiveView.TagEngine.component(
      Function.capture(module, function, 1),
      attributes,
      {env.module, env.function, env.file, env.line}
    )
  end

  def list do
    apps = Application.get_env(:live_capture, :apps, [])
    apps = if Enum.empty?(apps), do: [:live_capture], else: apps
    include_live_capture? = Enum.member?(apps, :live_capture)

    apps
    |> Enum.flat_map(fn app ->
      case :application.get_key(app, :modules) do
        {:ok, modules} -> modules
        _ -> []
      end
    end)
    |> Enum.reject(fn module ->
      not include_live_capture? and
        module |> Atom.to_string() |> String.starts_with?("Elixir.LiveCapture")
    end)
    |> Enum.uniq()
    |> Enum.filter(fn module ->
      has_captures = module.__info__(:functions) |> Keyword.has_key?(:__captures__)

      has_captures && Enum.any?(module.__captures__())
    end)
  end

  def attributes(module, function, variant \\ nil) do
    default_attributes =
      module.__components__()
      |> Map.get(function, %{})
      |> Map.get(:attrs, [])
      |> Enum.reduce(%{}, fn attr, acc ->
        value =
          case attr do
            %{opts: [examples: [example | _]]} -> example
            %{opts: [default: default]} -> default
            _ -> nil
          end

        Map.put(acc, attr.name, value)
      end)

    default_capture_attributes =
      module.__captures__() |> Map.get(function, %{}) |> Map.get(:attributes, %{})

    variants = module.__captures__() |> Map.get(function, %{}) |> Map.get(:variants, [])

    variant_attributes =
      Keyword.get_lazy(variants, variant, fn ->
        variants |> Keyword.values() |> List.first() |> Kernel.||(%{})
      end)

    default_attributes |> Map.merge(default_capture_attributes) |> Map.merge(variant_attributes)
  end
end
