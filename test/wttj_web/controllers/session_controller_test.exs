defmodule WttjWeb.SessionControllerTest do
  use WttjWeb.ConnCase, async: true

  alias Wttj.AccountsFixtures

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "create/2" do
    setup do
      account =
        AccountsFixtures.account_fixture(%{email: "minerva@hogwarts.com", password: "password"})

      %{account: account, account_id: account.id}
    end

    test "returns 200 and auth token when valid credentials are provided", %{
      conn: conn,
      account: account,
      account_id: account_id
    } do
      conn =
        post(conn, ~p"/api/sessions", %{"email" => account.email, "password" => account.password})

      assert %{"success" => true, "token" => _token, "current_user" => %{"id" => ^account_id}} =
               json_response(conn, 200)
    end

    test "returns error and no token with invalid credentials are provided", %{
      conn: conn,
      account: account
    } do
      conn =
        post(conn, ~p"/api/sessions", %{"email" => account.email, "password" => "bad-password"})

      assert json_response(conn, 401) == %{"error" => "Invalid credentials", "success" => false}
    end
  end
end
