defmodule Wttj.Accounts do
  alias Wttj.Accounts.Account
  alias Wttj.Repo

  def create(attrs \\ %{}) do
    %Account{}
    |> Account.changeset(attrs)
    |> Repo.insert()
  end

  def authenticate(nil, _password), do: {:error, :invalid_credentials}
  def authenticate(_email, nil), do: {:error, :invalid_credentials}

  def authenticate(email, password) do
    with account = %Account{} <- Repo.get_by(Account, email: email),
         true <- Bcrypt.verify_pass(password, account.password_hash) do
      {:ok, account}
    else
      nil ->
        Bcrypt.no_user_verify()
        {:error, :invalid_credentials}

      _ ->
        {:error, :invalid_credentials}
    end
  end

  def generate_token do
    :crypto.strong_rand_bytes(32) |> Base.url_encode64()
  end
end
