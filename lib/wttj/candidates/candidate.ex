defmodule Wttj.Candidates.Candidate do
  use Ecto.Schema

  import Ecto.Changeset

  alias Wttj.Candidates.CandidateStatuses

  @fields [:email, :status, :position, :job_id, :version]

  @derive {Jason.Encoder,
           only: [:id, :position, :status, :email, :job_id, :version, :inserted_at, :updated_at]}

  schema "candidates" do
    field :position, :integer

    field :status, Ecto.Enum,
      values: CandidateStatuses.statuses(),
      default: CandidateStatuses.new()

    field :email, :string
    field :job_id, :id
    field :version, :integer

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(candidate, attrs) do
    candidate
    |> cast(attrs, @fields)
    |> maybe_increment_version()
    |> validate_required(@fields)
  end

  defp maybe_increment_version(%{data: %{version: version}} = changeset) do
    changed_version = get_change(changeset, :version)

    case {version, changed_version} do
      {nil, nil} -> put_change(changeset, :version, 0)
      {nil, version} -> put_change(changeset, :version, version)
      {version, nil} -> put_change(changeset, :version, version + 1)
      {_version, _changed_version} -> changeset
    end
  end
end
