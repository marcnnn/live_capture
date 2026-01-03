defmodule LiveCapture.RawComponent.ShowLive do
  use LiveCapture.Web, :live_view

  def mount(params, session, socket) do
    module = LiveCapture.Component.list() |> Enum.find(&(to_string(&1) == params["module"]))

    function =
      module.__captures__ |> Map.keys() |> Enum.find(&(to_string(&1) == params["function"]))

    variants =
      module.__captures__
      |> Map.get(function, %{})
      |> Map.get(:variants, [])
      |> Keyword.keys()

    variant = select_variant(variants, params["variant"])

    attrs = LiveCapture.Component.attrs(module, function, variant)
    slots = LiveCapture.Component.slots(module, function, variant)

    {:ok,
     assign(socket,
       module: module,
       function: function,
       variant: variant,
       attrs: Map.merge(attrs, slots)
     )}
  end

  def render(assigns) do
    ~H"""
    <%= Phoenix.LiveView.TagEngine.component(
      Function.capture(@module, @function, 1),
      @attrs,
      {__ENV__.module, __ENV__.function, __ENV__.file, __ENV__.line}
    ) %>
    """
  end

  defp select_variant(variants, variant_param) do
    cond do
      variant_param in [nil, ""] && variants != [] ->
        List.first(variants)

      variant_param && variant_param in Enum.map(variants, &to_string/1) ->
        String.to_existing_atom(variant_param)

      variants != [] ->
        List.first(variants)

      true ->
        nil
    end
  end
end
