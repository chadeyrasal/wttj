defmodule Wttj.Repo.Migrations.AddVersionToCandidates do
  use Ecto.Migration

  def change do
    alter table(:candidates) do
      add :version, :integer, default: 0
    end
  end
end
