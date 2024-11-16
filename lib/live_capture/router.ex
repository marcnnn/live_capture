defmodule LiveCapture.Router do
  defmodule __MODULE__.Assets do
    import Plug.Conn
    def init(opts), do: opts
    def call(conn, _), do: put_private(conn, :plug_skip_csrf_protection, true)
  end

  defmacro live_capture(path) do
    quote bind_quoted: binding() do
      import Phoenix.Router
      import Phoenix.LiveView.Router, only: [live: 2, live_session: 2]

      pipeline :live_capture_static do
        plug LiveCapture.Router.Assets

        plug Plug.Static,
          at: "/",
          from: :live_capture,
          only: ~w(css js)
      end

      pipeline :live_capture_browser do
        plug :put_root_layout, html: {LiveCapture.Layouts, :root}
      end

      scope path do
        pipe_through :live_capture_browser

        live_session :live_capture do
          live("/", LiveCapture.Component.ShowLive)
          live("/components/:module/:function", LiveCapture.Component.ShowLive)
          live("/raw/components/:module/:function", LiveCapture.RawComponent.ShowLive)
        end

        pipe_through :live_capture_static

        get "/*not_found", LiveCapture.PageController, :not_found
      end
    end
  end
end
