defmodule Wttj.AccountsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Wttj.Accounts` context.
  """

  def unique_user_email, do: "user#{System.unique_integer()}@example.com"

  @doc """
  Generate a valid account.
  """
  def account_fixture(attrs \\ %{}) do
    {:ok, account} =
      attrs
      |> Enum.into(%{email: unique_user_email(), password: "password"})
      |> Wttj.Accounts.create()

    account
  end
end
