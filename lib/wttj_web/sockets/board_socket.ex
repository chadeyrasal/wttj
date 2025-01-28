defmodule WttjWeb.BoardSocket do
  use Phoenix.Socket

  channel "board:*", WttjWeb.BoardChannel

  @impl true
  def connect(%{"token" => _token}, socket, _connect_info) do
    {:ok, socket}
  end

  @impl true
  def id(_socket), do: nil
end
