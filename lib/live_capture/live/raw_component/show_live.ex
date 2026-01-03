defmodule LiveCapture.RawComponent.ShowLive do
  use LiveCapture.Web, :live_view

  def mount(params, session, socket) do
    module = LiveCapture.Component.list() |> Enum.find(&(to_string(&1) == params["module"]))

    function =
      module.__captures__ |> Map.keys() |> Enum.find(&(to_string(&1) == params["function"]))

    {:ok, assign(socket, module: module, function: function)}
  end

  def handle_params(params, uri, socket) do
    %{"custom_params" => custom_params} = URI.parse(uri).query |> Plug.Conn.Query.decode()
    custom_params = if custom_params == "", do: %{}, else: custom_params

    phoenix_component = socket.assigns.module.__components__[socket.assigns.function] || %{}

    attrs = LiveCapture.Component.attrs(socket.assigns.module, socket.assigns.function)
    slots = LiveCapture.Component.slots(socket.assigns.module, socket.assigns.function)

    {:noreply, assign(socket, attrs: Map.merge(attrs, slots))}
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
end
