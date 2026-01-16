defmodule LiveCapture.Attribute do
  defstruct [:module, :resolver]

  def with_csp_nonces(resolver) when is_function(resolver, 1) do
    %__MODULE__{module: __MODULE__.CSPNonces, resolver: resolver}
  end

  def resolve(%__MODULE__{module: module, resolver: resolver}, conn_assigns) do
    conn_assigns |> module.config() |> resolver.()
  end

  def resolve(value, _conn_assigns), do: value

  defmodule CSPNonces do
    def config(conn_assigns), do: Map.take(conn_assigns, [:csp_style_nonce, :csp_script_nonce])
  end
end
