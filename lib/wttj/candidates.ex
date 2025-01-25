defmodule Wttj.Candidates do
  @moduledoc """
  The Candidates context.
  """

  import Ecto.Query, warn: false

  alias Ecto.Multi

  alias Wttj.Repo
  alias Wttj.Candidates.Candidate

  @doc """
  Returns the list of candidates.

  ## Examples

      iex> list_candidates()
      [%Candidate{}, ...]

  """
  def list_candidates(job_id) do
    query = from c in Candidate, where: c.job_id == ^job_id
    Repo.all(query)
  end

  @doc """
  Gets a single candidate.

  Raises `Ecto.NoResultsError` if the Candidate does not exist.

  ## Examples

      iex> get_candidate!(123)
      %Candidate{}

      iex> get_candidate!(456)
      ** (Ecto.NoResultsError)

  """
  def get_candidate!(job_id, id), do: Repo.get_by!(Candidate, id: id, job_id: job_id)

  @doc """
  Creates a candidate.

  ## Examples

      iex> create_candidate(%{field: value})
      {:ok, %Candidate{}}

      iex> create_candidate(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_candidate(attrs \\ %{}) do
    %Candidate{}
    |> Candidate.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a candidate.

  ## Examples

      iex> update_candidate(candidate, %{field: new_value})
      {:ok, %Candidate{}}

      iex> update_candidate(candidate, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_candidate(%Candidate{} = candidate, attrs) do
    candidate
    |> Candidate.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking candidate changes.

  ## Examples

      iex> change_candidate(candidate)
      %Ecto.Changeset{data: %Candidate{}}

  """
  def change_candidate(%Candidate{} = candidate, attrs \\ %{}) do
    Candidate.changeset(candidate, attrs)
  end

  # TODO: make the arg into a struct so we can validate the data before any expensive operation
  def reorder_candidates(job_id, candidate_id, source_column, destination_column, new_position)
      when source_column == destination_column do
    %{position: old_position} = candidate = get_candidate!(job_id, candidate_id)

    cond do
      old_position == new_position ->
        {:ok, :noop}

      # Moving candidate up
      old_position > new_position ->
        Multi.new()
        |> Multi.run(:move_all_down_by_one, fn _repo, _ ->
          move_all_down_by_one(job_id, source_column, new_position)
        end)
        |> Multi.run(:update_candidate, fn _repo, _ ->
          update_candidate(candidate, %{position: new_position})
        end)
        |> Multi.run(:move_all_up_by_one, fn _repo, _ ->
          move_all_up_by_one(job_id, source_column, old_position + 1)
        end)
        |> Repo.transaction()

      # Moving candidate down
      old_position < new_position ->
        Multi.new()
        |> Multi.run(:move_all_down_by_one, fn _repo, _ ->
          move_all_down_by_one(job_id, source_column, new_position + 1)
        end)
        |> Multi.run(:update_candidate, fn _repo, _ ->
          update_candidate(candidate, %{position: new_position + 1})
        end)
        |> Multi.run(:move_all_up_by_one, fn _repo, _ ->
          move_all_up_by_one(job_id, source_column, old_position)
        end)
        |> Repo.transaction()
    end
  end

  # TODO: make the arg into a struct so we can validate the data before any expensive operation
  def reorder_candidates(job_id, candidate_id, source_column, destination_column, new_position) do
    %{position: old_position} = candidate = get_candidate!(job_id, candidate_id)

    Multi.new()
    |> Multi.run(:move_all_down_by_one, fn _repo, _ ->
      move_all_down_by_one(job_id, destination_column, new_position)
    end)
    |> Multi.run(:update_candidate, fn _repo, _ ->
      update_candidate(candidate, %{position: new_position, status: destination_column})
    end)
    |> Multi.run(:move_all_up_by_one, fn _repo, _ ->
      move_all_up_by_one(job_id, source_column, old_position)
    end)
    |> Repo.transaction()
  end

  defp move_all_up_by_one(job_id, column, position) do
    {number_of_updated_records, nil} =
      from(c in Candidate,
        where: c.job_id == ^job_id,
        where: c.status == ^column,
        where: c.position > ^position
      )
      |> Repo.update_all(inc: [position: -1])

    {:ok, "#{number_of_updated_records} record(s) updated"}
  end

  defp move_all_down_by_one(job_id, column, position) do
    from(c in Candidate,
      where: c.job_id == ^job_id,
      where: c.status == ^column,
      where: c.position >= ^position,
      order_by: [desc: c.position]
    )
    |> Repo.all()
    |> Enum.reduce_while(0, fn %{position: position} = candidate, acc ->
      case update_candidate(candidate, %{position: position + 1}) do
        {:ok, _candidate} -> {:cont, acc}
        {:error, _changeset} -> {:halt, candidate.id}
      end
    end)
    |> case do
      0 -> {:ok, "All records updated"}
      _ -> {:error, "Failed to update records"}
    end
  end
end
