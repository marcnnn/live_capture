defmodule CaptureUI.Example do
  use Phoenix.Component
  use CaptureUI.Component

  capture()

  def hello(assigns) do
    ~H"""
    <p>Hello world!</p>
    """
  end
end

defmodule CaptureUI.Main.ShowLive do
  use CaptureUI.Web, :live_view

  def mount(_, _, socket) do
    components = CaptureUI.Component.list()

    {:ok, assign(socket, components: components)}
  end

  def render(assigns) do
    ~H"""
    <div class="flex min-h-svh">
      <div class="w-96 border-r">
        <div class="text-xl">Components</div>
        <div
          :for={component <- @components}
          class="py-4 hover:bg-slate-200 cursor-pointer"
          phx-click="component:show"
          phx-value-component={component}
        >
          <%= component %>
        </div>
      </div>
      <div class="flex-1 flex flex-col">
        <div class="flex-1">Main</div>
        <div class="border-t">Attributes</div>
      </div>
    </div>
    """
  end
end
