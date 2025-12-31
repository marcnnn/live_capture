defmodule LiveCapture.Component.Components.Docs do
  use Phoenix.Component
  import Phoenix.HTML, only: [raw: 1]

  @theme %{
    colors: %{
      wrapper_bg: "bg-white",
      wrapper_text: "text-slate-900",
      keyword: "text-indigo-600",
      module: "text-sky-700",
      function: "text-emerald-700",
      attr_name: "text-amber-700",
      operator: "text-slate-500",
      value: "text-slate-800",
      string: "text-orange-700",
      atom: "text-fuchsia-700",
      number: "text-emerald-700",
      punctuation: "text-slate-500",
      default: "text-slate-700"
    }
  }

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
    module_name =
      assigns.component.module
      |> to_string()
      |> String.replace_prefix("Elixir.", "")

    aliased_name =
      module_name
      |> String.split(".")
      |> List.last()

    assigns =
      assigns
      |> assign(:module_name, module_name)
      |> assign(:aliased_name, aliased_name)

    ~H"""
    <div
      class={[
        "block rounded-lg p-4 font-mono text-sm leading-relaxed",
        color(:wrapper_bg),
        color(:wrapper_text)
      ]}
      phx-no-format
    >
      <.alias_line module_name={@module_name} />
      <div><br /></div>
      <.component_call aliased_name={@aliased_name} component={@component} />
    </div>
    """
  end

  defp alias_line(assigns) do
    ~H"""
    <div><%= highlight("alias ", :keyword) %><%= highlight(@module_name, :module) %></div>
    """
  end

  defp component_call(assigns) do
    assigns =
      assigns
      |> assign(:function_name, assigns.component[:function] |> to_string())
      |> assign(:attr_list, attr_examples(assigns.component[:attrs]))

    ~H"""
    <%= if @attr_list == [] do %>
      <div>&lt;<%= highlight(@aliased_name, :module) %>.<%= highlight(@function_name, :function) %> /&gt;</div>
    <% else %>
      <div>&lt;<%= highlight(@aliased_name, :module) %>.<%= highlight(@function_name, :function) %></div>
      <.attrs list={@attr_list} />
      <div>/&gt;</div>
    <% end %>
    """
  end

  defp attrs(assigns) do
    assigns = assign(assigns, :attrs, assigns.list || [])

    ~H"""
    <div class="ml-4">
      <%= for {name, example} <- @attrs do %>
        <%= if multiline_value?(example) do %>
          <div><%= highlight(name, :attr_name) %><%= highlight("=", :operator) %><%= highlight("{", :punctuation) %></div>
          <%= render_value_lines(example, 2) %>
          <div><%= highlight("}", :punctuation) %></div>
        <% else %>
          <div><%= highlight(name, :attr_name) %><%= highlight("=", :operator) %><%= render_inline(example) %></div>
        <% end %>
      <% end %>
    </div>
    """
  end

  defp attr_examples(list) do
    (list || [])
    |> Enum.flat_map(fn
      %{name: name, opts: [examples: [example | _]]} ->
        [{name, example}]

      _ ->
        []
    end)
  end

  defp highlight(text, category) do
    assigns = %{text: to_string(text), classes: category_classes(category)}

    ~H"""
    <span class={@classes}><%= @text %></span>
    """
  end

  defp highlight(value) do
    value
    |> value_lines(0)
    |> lines_to_html()
  end

  defp render_value_lines(value, indent) do
    value
    |> value_lines(indent)
    |> lines_to_html()
  end

  defp render_inline(value) do
    value
    |> value_lines(0)
    |> inline_tokens()
    |> raw()
  end

  defp multiline_value?(value) when is_map(value) or is_list(value) or is_tuple(value), do: true
  defp multiline_value?(%_{}), do: true
  defp multiline_value?(_), do: false

  defp value_lines(value, indent) when is_binary(value) do
    [
      {indent,
       [highlight_token("\"", :punctuation), highlight_token(value, :string), highlight_token("\"", :punctuation)]}
    ]
  end

  defp value_lines(value, indent) when is_atom(value) do
    [{indent, [highlight_token(":", :operator), highlight_token(Atom.to_string(value), :atom)]}]
  end

  defp value_lines(value, indent) when is_integer(value) or is_float(value) do
    [{indent, [highlight_token(to_string(value), :number)]}]
  end

  defp value_lines(list, indent) when is_list(list) do
    if list == [] do
      [{indent, [highlight_token("[]", :punctuation)]}]
    else
      list_lines(list, indent)
    end
  end

  defp list_lines(list, indent) do
    if inline_list?(list) do
      parts =
        list
        |> Enum.map(&value_lines(&1, 0))
        |> Enum.map(&lines_to_tokens/1)
        |> Enum.intersperse(highlight_token(", ", :punctuation))

      [{indent, [highlight_token("[", :punctuation), parts, highlight_token("]", :punctuation)]}]
    else
      open = {indent, [highlight_token("[", :punctuation)]}

      inner =
        list
        |> Enum.with_index()
        |> Enum.flat_map(fn {item, idx} ->
          suffix = if idx < length(list) - 1, do: highlight_token(",", :punctuation), else: nil
          item |> value_lines(indent + 2) |> append_suffix(suffix)
        end)

      close = {indent, [highlight_token("]", :punctuation)]}
      [open | inner] ++ [close]
    end
  end

  defp value_lines(%struct{} = value, indent) do
    module =
      struct
      |> Module.split()
      |> List.last()

    fields = Map.from_struct(value) |> Enum.to_list()
    open = {indent, [highlight_token("%", :operator), highlight_token(module, :module), highlight_token("{", :punctuation)]}

    inner = render_pairs(fields, indent + 2)
    close = {indent, [highlight_token("}", :punctuation)]}

    [open | inner] ++ [close]
  end

  defp value_lines(map, indent) when is_map(map) do
    if map == %{} do
      [{indent, [highlight_token("%{}", :punctuation)]}]
    else
      map_lines(map, indent)
    end
  end

  defp map_lines(map, indent) do
    pairs = map |> Enum.to_list()
    open = {indent, [highlight_token("%{", :punctuation)]}
    inner = render_pairs(pairs, indent + 2)
    close = {indent, [highlight_token("}", :punctuation)]}

    [open | inner] ++ [close]
  end

  defp value_lines({a, b}, indent) do
    open = {indent, [highlight_token("{", :punctuation)]}

    inner =
      [{a, 0}, {b, 1}]
      |> Enum.flat_map(fn {item, idx} ->
        suffix = if idx == 0, do: highlight_token(", ", :punctuation), else: nil
        item |> value_lines(indent + 2) |> append_suffix(suffix)
      end)

    close = {indent, [highlight_token("}", :punctuation)]}
    [open | inner] ++ [close]
  end

  defp value_lines(value, indent) do
    [{indent, [highlight_token(inspect(value), :value)]}]
  end

  defp render_pairs(pairs, indent) do
    total = length(pairs)

    pairs
    |> Enum.with_index()
    |> Enum.flat_map(fn {{k, v}, idx} ->
      suffix = if idx < total - 1, do: highlight_token(",", :punctuation), else: nil
      render_pair(k, v, indent, suffix)
    end)
  end

  defp render_pair(key, value, indent, suffix) do
    lines = value_lines(value, indent)

    case lines do
      [{_child_indent, parts} | rest] ->
        new_first =
          {indent,
           key_tokens(key) ++
             [highlight_token(": ", :operator)] ++ parts}

        ([new_first | rest] |> append_suffix(suffix))

      _ ->
        append_suffix([{indent, key_tokens(key) ++ [highlight_token(": ", :operator)]}], suffix)
    end
  end

  defp lines_to_tokens(lines) do
    case lines do
      [{_indent, parts}] ->
        parts

      _ ->
        lines
        |> lines_to_html()
        |> Phoenix.HTML.Safe.to_iodata()
    end
  end

  defp lines_to_html(lines) do
    iodata =
      lines
      |> Enum.map(fn {indent, parts} ->
        padding = String.duplicate("&nbsp;", indent)
        content = parts |> List.wrap() |> Enum.map(&Phoenix.HTML.Safe.to_iodata/1)
        ["<div>", padding, content, "</div>"]
      end)

    raw(iodata)
  end

  defp inline_tokens([{_indent, parts}]) do
    parts
    |> List.wrap()
    |> Enum.map(&Phoenix.HTML.Safe.to_iodata/1)
  end

  defp append_suffix(lines, nil), do: lines

  defp append_suffix([], _suffix), do: []

  defp append_suffix(lines, suffix) do
    {indent, parts} = List.last(lines)
    List.replace_at(lines, -1, {indent, parts ++ [suffix]})
  end

  defp inline_list?(list) do
    short? = length(list) <= 5
    simple? = Enum.all?(list, &(!multiline_value?(&1)))
    short? and simple?
  end

  defp key_tokens(key) when is_atom(key) do
    [highlight_token(Atom.to_string(key), :atom)]
  end

  defp key_tokens(key) when is_binary(key) do
    [
      highlight_token("\"", :punctuation),
      highlight_token(key, :string),
      highlight_token("\"", :punctuation)
    ]
  end

  defp key_tokens(key), do: [highlight_token(inspect(key), :value)]

  defp highlight_token(text, category) do
    escaped =
      text
      |> to_string()
      |> Phoenix.HTML.html_escape()
      |> Phoenix.HTML.Safe.to_iodata()

    class =
      category_classes(category)
      |> Enum.join(" ")

    {:safe, ["<span class=\"", class, "\">", escaped, "</span>"]}
  end

  defp category_classes(category) do
    tone = color(category)

    ["docs-syntax", tone]
  end

  defp color(category), do: Map.get(@theme.colors, category, @theme.colors[:default])
end
