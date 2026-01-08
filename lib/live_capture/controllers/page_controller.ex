defmodule LiveCapture.PageController do
  use Phoenix.Controller, formats: [:html]

  def not_found(conn, _) do
    send_resp(conn, 404, "Not found")
  end
end
