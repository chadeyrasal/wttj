defmodule Wttj.AccountsTest do
  use Wttj.DataCase, async: true

  alias Ecto.Changeset

  alias Wttj.{Accounts, AccountsFixtures, Repo}
  alias Wttj.Accounts.Account

  describe "create/1" do
    test "returns newly inserted record when valid data is provided" do
      assert Repo.aggregate(Account, :count) == 0

      assert {:ok, %Account{email: "minerva@hogwarts.com"}} =
               Accounts.create(%{email: "minerva@hogwarts.com", password: "password"})

      assert Repo.aggregate(Account, :count) == 1
    end

    test "returns error when invalid data is provided" do
      assert {:error, %Changeset{valid?: false, errors: errors}} =
               Accounts.create(%{email: "invalid-email"})

      assert errors == [
               email: {"has invalid format", [validation: :format]},
               password: {"can't be blank", [validation: :required]}
             ]
    end
  end

  describe "authenticate/2" do
    setup do
      account =
        AccountsFixtures.account_fixture(%{email: "minerva@hogwarts.com", password: "password"})

      %{account: account}
    end

    test "returns account details when the provided credentials are valid" do
      assert {:ok, %{email: "minerva@hogwarts.com"}} =
               Accounts.authenticate("minerva@hogwarts.com", "password")
    end

    test "errors when the email provided is nil" do
      assert {:error, :invalid_credentials} = Accounts.authenticate(nil, "password")
    end

    test "errors when the password provided is nil" do
      assert {:error, :invalid_credentials} = Accounts.authenticate("albus@hogwarts.com", nil)
    end

    test "errors when no user is found for provided email" do
      assert {:error, :invalid_credentials} =
               Accounts.authenticate("albus@hogwarts.com", "password")
    end
  end
end
