defmodule Wttj.CandidatesTest do
  use Wttj.DataCase

  import Wttj.CandidatesFixtures
  import Wttj.JobsFixtures

  alias Ecto.Changeset

  alias Wttj.Candidates
  alias Wttj.Candidates.Candidate

  @invalid_attrs %{position: nil, status: nil, email: nil}

  setup do
    job_1 = job_fixture()
    candidate_1 = candidate_fixture(%{job_id: job_1.id})

    %{job_1: job_1, candidate_1: candidate_1}
  end

  describe "list_candidates/1" do
    test "returns all candidates for a given job", %{job_1: job_1, candidate_1: candidate_1} do
      job_2 = job_fixture()
      _candidate_2 = candidate_fixture(%{job_id: job_2.id})

      assert Candidates.list_candidates(job_1.id) == [candidate_1]
    end
  end

  describe "create_candidate/1" do
    test "with valid data creates a candidate", %{job_1: %{id: job_id}} do
      email = unique_user_email()
      valid_attrs = %{email: email, position: 3, job_id: job_id}

      assert {:ok, %Candidate{email: ^email, position: 3, job_id: ^job_id}} =
               Candidates.create_candidate(valid_attrs)
    end

    test "with invalid data returns error changeset" do
      assert {:error, %Changeset{}} = Candidates.create_candidate(@invalid_attrs)
    end
  end

  describe "update_candidate/2" do
    test "with valid data updates the candidate", %{candidate_1: candidate_1} do
      email = unique_user_email()
      update_attrs = %{position: 43, status: :rejected, email: email}

      assert {:ok, %Candidate{position: 43, status: :rejected, email: ^email}} =
               Candidates.update_candidate(candidate_1, update_attrs)
    end

    test "with invalid data returns error changeset", %{
      job_1: %{id: job_id},
      candidate_1: candidate_1
    } do
      assert {:error, %Changeset{}} = Candidates.update_candidate(candidate_1, @invalid_attrs)

      assert Candidates.get_candidate!(job_id, candidate_1.id) == candidate_1
    end
  end

  describe "change_candidate/1" do
    test "returns a candidate changeset", %{candidate_1: candidate_1} do
      assert %Changeset{valid?: true, changes: %{}, errors: []} =
               Candidates.change_candidate(candidate_1)
    end
  end
end
