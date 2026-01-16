defmodule LiveCapture.Plugs.AssetsConfig do
  import Plug.Conn

  def init(opts), do: opts

  def call(conn, opts) do
    conn
    |> put_private(:live_capture_path, opts |> Keyword.fetch!(:scope) |> assets_scope())
    |> put_private(:csp_nonce_assign_key, Keyword.fetch!(opts, :csp_nonce_assign_key))
  end

  def live_session(conn) do
    style_key = conn.private.csp_nonce_assign_key[:style]

    %{"csp_style_nonce" => style_key && Map.get(conn.assigns, style_key)}
  end

  def assets_scope("/"), do: ""
  def assets_scope(val), do: val
end
