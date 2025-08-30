defmodule LiveCapture.Component.Components.Form do
  use Phoenix.Component
  use LiveCapture.Component

  attr :name, :string, required: true, examples: ["name"]
  attr :options, :list, required: true, examples: [["Variant 1", 2, 3]]
  attr :selected, :any, default: nil, examples: [2]
  attr :class, :string, default: ""

  capture()

  def options(assigns) do
    ~H"""
    <div class="inline-flex rounded-full border overflow-hidden">
      <div :for={option <- @options}>
        <input
          type="radio"
          name={@name}
          id={"#{@name}-#{option}"}
          value={option}
          checked={@selected == option}
          class="hidden peer"
        />
        <label
          for={"#{@name}-#{option}"}
          class="cursor-pointer px-4 py-2 peer-checked:bg-blue-200 peer-checked:hover:bg-blue-200 hover:bg-blue-100 peer-checked:hover:bg-blue-100"
        >
          <%= option %>
        </label>
      </div>
    </div>
    """
  end
end
