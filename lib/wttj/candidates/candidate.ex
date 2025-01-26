defmodule Wttj.Candidates.Candidate do
  use Ecto.Schema

  import Ecto.Changeset

  alias Wttj.Candidates.CandidateStatuses

  schema "candidates" do
    field :position, :integer

    field :status, Ecto.Enum,
      values: CandidateStatuses.statuses(),
      default: CandidateStatuses.new()

    field :email, :string
    field :job_id, :id

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(candidate, attrs) do
    candidate
    |> cast(attrs, [:email, :status, :position, :job_id])
    |> validate_required([:email, :status, :position, :job_id])
  end
end
