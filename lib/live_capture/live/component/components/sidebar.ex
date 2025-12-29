defmodule LiveCapture.Component.Components.Sidebar do
  use Phoenix.Component
  use LiveCapture.Component

  attr :modules, :list,
    required: true,
    examples: [[LiveCapture.Component.Components.Example]]

  attr :component, :map,
    default: nil,
    examples: [
      %{
        module: LiveCapture.Component.Components.Example,
        function: :hello_world,
        attrs: [%{name: :title, opts: [examples: ["Earth"]]}]
      }
    ]

  capture()

  def show(assigns) do
    ~H"""
    <div>
      <.title />

      <div class="space-y-2">
        <div :for={module <- @modules}>
          <% is_selected = @component[:module] == module %>
          <.module_title module={module} is_selected={is_selected} />
          <div class="mx-4">
            <.functions_list
              :if={is_selected}
              module={module}
              component={@component}
              is_selected={is_selected}
            />
          </div>
        </div>
      </div>
    </div>
    """
  end

  defp title(assigns) do
    ~H"""
    <div class="m-4 font-bold text-primary"><.link navigate="/">LiveCapture</.link></div>
    """
  end

  attr :module, :any, required: true
  attr :is_selected, :boolean, required: true

  defp module_title(%{is_selected: true} = assigns) do
    ~H"""
    <div class="text-primary border-l-4 border-primary px-3">
      <%= @module %>
    </div>
    """
  end

  defp module_title(%{is_selected: false} = assigns) do
    ~H"""
    <div class="mx-4">
      <.link navigate={"/components/#{@module}/#{Enum.at(@module.__captures__, 0) |> elem(0)}"}>
        <%= @module %>
      </.link>
    </div>
    """
  end

  attr :module, :any, required: true
  attr :component, :map, required: true
  attr :is_selected, :boolean, required: true

  defp functions_list(assigns) do
    ~H"""
    <ul class="border-l border-slate-300 my-4">
      <li :for={{capture, _} <- @module.__captures__}>
        <.link
          navigate={"/components/#{@module}/#{capture}"}
          class={[
            "-ml-px block pl-4 border-l cursor-pointer",
            (@is_selected && capture == @component[:function] &&
               "border-primary text-primary") ||
              "hover:text-slate-900 hover:border-slate-700 border-slate-300 text-slate-700"
          ]}
        >
          <%= capture %>/<%= attr_count(@module, capture) %>
        </.link>
      </li>
    </ul>
    """
  end

  defp attr_count(module, capture) do
    module.__components__
    |> Map.get(capture, %{})
    |> Map.get(:attrs, [])
    |> length()
  end
end
