defmodule WttjWeb.SessionController do
  use WttjWeb, :controller

  alias Wttj.Accounts

  action_fallback WttjWeb.FallbackController

  def create(conn, %{"email" => email, "password" => password}) do
    case Accounts.authenticate(email, password) do
      {:ok, account} ->
        token = Accounts.generate_token()
        json(conn, %{success: true, token: token, current_user: %{id: account.id}})

      {:error, :invalid_credentials} ->
        conn
        |> put_status(:unauthorized)
        |> json(%{success: false, error: "Invalid credentials"})
    end
  end
end
