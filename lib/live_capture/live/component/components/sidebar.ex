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
    <.section
      :for={module <- @modules}
      module={module}
      component={@component}
      is_selected={@component[:module] == module}
    />
    """
  end

  attr :module, :any, required: true
  attr :component, :map, required: true
  attr :is_selected, :boolean, required: true

  defp section(assigns) do
    ~H"""
    <section class={[
      "py-1 px-2 border-l-2 hover:border-primary hover:bg-primary/5",
      @is_selected && "bg-primary/5 border-primary"
    ]}>
      <.module_title module={@module} is_selected={@is_selected} />
      <.functions_list :if={@is_selected} module={@module} component={@component} />
    </section>
    """
  end

  attr :module, :any, required: true
  attr :is_selected, :boolean, required: true

  defp module_title(%{is_selected: true} = assigns) do
    ~H"""
    <div class="text-primary">
      <%= @module %>
    </div>
    """
  end

  defp module_title(%{is_selected: false} = assigns) do
    ~H"""
    <div>
      <.link navigate={"/components/#{@module}/#{Enum.at(@module.__captures__, 0) |> elem(0)}"}>
        <%= @module %>
      </.link>
    </div>
    """
  end

  attr :module, :any, required: true
  attr :component, :map, required: true

  defp functions_list(assigns) do
    ~H"""
    <ul class="ml-4 py-2">
      <.function
        :for={{capture, config} <- @module.__captures__}
        module={@module}
        capture={capture}
        attr_count={attr_count(@module, capture)}
        variants={Keyword.keys(config[:variants] || [])}
        is_selected={capture == @component[:function]}
        selected_variant={@component[:variant]}
      />
    </ul>
    """
  end

  attr :module, :any, required: true
  attr :capture, :any, required: true
  attr :attr_count, :integer, required: true
  attr :variants, :list, default: []
  attr :is_selected, :boolean, required: true
  attr :selected_variant, :any

  defp function(%{is_selected: true} = assigns) do
    ~H"""
    <li>
      <div class="block border-l-2 border-primary px-3 cursor-pointer text-primary">
        <%= @capture %>/<%= @attr_count %>
      </div>

      <ul :if={Enum.any?(@variants)} class="pt-1 pb-2">
        <li :for={variant <- @variants}>
          <.link
            navigate={"/components/#{@module}/#{@capture}/#{variant}"}
            class={[
              "group flex items-center gap-2 px-3 cursor-pointer",
              variant == @selected_variant &&
                "text-primary",
              variant != @selected_variant &&
                "text-slate-700 hover:text-primary"
            ]}
          >
            <span class={[
              "text-primary font-md text-xl leading-none",
              variant == @selected_variant && "opacity-100",
              variant != @selected_variant && "opacity-0 group-hover:opacity-100"
            ]}>
              &bull;
            </span>
            <%= variant %>
          </.link>
        </li>
      </ul>
    </li>
    """
  end

  defp function(%{is_selected: false} = assigns) do
    ~H"""
    <li>
      <.link
        navigate={"/components/#{@module}/#{@capture}"}
        class="block border-l-2 px-3 cursor-pointer hover:text-primary hover:border-primary border-slate-300 text-slate-700"
      >
        <%= @capture %>/<%= @attr_count %>
      </.link>
    </li>
    """
  end

  defp attr_count(module, capture) do
    module.__components__
    |> Map.get(capture, %{})
    |> Map.get(:attrs, [])
    |> length()
  end
end
