defmodule LiveCapture.Component.Components.Docs do
  use Phoenix.Component

  attr :component, :map,
    required: true,
    examples: [
      %{
        module: LiveCapture.Component.Components.Example,
        function: :hello_world,
        attrs: [%{name: :title, opts: [examples: ["Earth"]]}]
      }
    ]

  def show(assigns) do
    assigns = assign(assigns, aliased: assigns.component.module |> to_string())

    ~H"""
    <code class="whitespace-pre" phx-no-format>
    alias <%= @component[:module] %>

    &lt;<%= @aliased %>.<%= @component[:function] %>
    <.attrs list={@component[:attrs]} />
    /&gt;
    </code>
    """
  end

  defp attrs(assigns) do
    signature =
      (assigns.list || [])
      |> Enum.map(fn attr ->
        case attr do
          %{name: name, opts: [examples: [example | _]]} ->
            [
              name,
              example
              |> inspect()
              |> Code.format_string!()
              |> Enum.join("")
              |> String.split("\n")
              |> Enum.join("\n")
            ]
            |> Enum.join("=")

          _ ->
            ""
        end
      end)
      |> Enum.join("\n")

    assigns = assign(assigns, :signature, signature)

    ~H"""
    <div class="ml-4"><%= @signature %></div>
    """
  end
end
