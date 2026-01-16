defmodule LiveCapture.Plugs.LoaderPlugs do
  def init(opts), do: opts

  def call(conn, opts) do
    component_loaders = Keyword.fetch!(opts, :component_loaders)
    loader = resolve_loader(conn, component_loaders)

    plugs = if loader, do: List.wrap(loader.plugs()), else: []

    Enum.reduce(plugs, conn, &apply_plug/2)
  end

  defp resolve_loader(%{params: %{"module" => module_param}}, component_loaders) do
    component_loaders
    |> LiveCapture.Component.list()
    |> Enum.find(&(to_string(&1) == module_param))
    |> case do
      nil -> nil
      module -> module.__live_capture__()[:loader]
    end
  end

  defp resolve_loader(_, _), do: nil

  defp apply_plug({plug, plug_opts}, conn) do
    plug.call(conn, plug.init(plug_opts))
  end

  defp apply_plug(plug, conn) do
    plug.call(conn, plug.init([]))
  end
end
