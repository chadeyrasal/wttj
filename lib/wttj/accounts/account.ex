defmodule Wttj.Accounts.Account do
  use Ecto.Schema

  import Ecto.Changeset

  @field [:email, :password]

  schema "accounts" do
    field :email, :string
    field :password_hash, :string
    field :password, :string, virtual: true

    timestamps(type: :utc_datetime)
  end

  def changeset(account = %__MODULE__{}, attrs) do
    account
    |> cast(attrs, @field)
    |> validate_required(@field)
    |> validate_format(:email, ~r/@/)
    |> unique_constraint(:email)
    |> put_password_hash()
  end

  defp put_password_hash(%{valid?: true, changes: %{password: password}} = changeset) do
    put_change(changeset, :password_hash, Bcrypt.hash_pwd_salt(password))
  end

  defp put_password_hash(changeset), do: changeset
end
