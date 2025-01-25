defmodule Wttj.CandidatesTest do
  use Wttj.DataCase

  import Wttj.CandidatesFixtures
  import Wttj.JobsFixtures

  alias Ecto.Changeset

  alias Wttj.{Candidates, Repo}
  alias Wttj.Candidates.Candidate

  @invalid_attrs %{position: nil, status: nil, email: nil}

  setup do
    job_1 = job_fixture()
    candidate = candidate_fixture(%{job_id: job_1.id})

    %{job_1: job_1, candidate: candidate}
  end

  describe "list_candidates/1" do
    test "returns all candidates for a given job", %{job_1: job_1, candidate: candidate_1} do
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
    test "with valid data updates the candidate", %{candidate: candidate} do
      email = unique_user_email()
      update_attrs = %{position: 43, status: :rejected, email: email}

      assert {:ok, %Candidate{position: 43, status: :rejected, email: ^email}} =
               Candidates.update_candidate(candidate, update_attrs)
    end

    test "with invalid data returns error changeset", %{
      job_1: %{id: job_id},
      candidate: candidate
    } do
      assert {:error, %Changeset{}} = Candidates.update_candidate(candidate, @invalid_attrs)

      assert Candidates.get_candidate!(job_id, candidate.id) == candidate
    end
  end

  describe "change_candidate/1" do
    test "returns a candidate changeset", %{candidate: candidate} do
      assert %Changeset{valid?: true, changes: %{}, errors: []} =
               Candidates.change_candidate(candidate)
    end
  end

  describe("reorder_candidate/4") do
    setup do
      %{id: job_id} = job_fixture()

      candidate_new_1 =
        candidate_fixture(%{job_id: job_id, status: :new, position: 1})

      candidate_new_2 =
        candidate_fixture(%{job_id: job_id, status: :new, position: 2})

      candidate_new_3 =
        candidate_fixture(%{job_id: job_id, status: :new, position: 3})

      %{
        candidate_new_1: candidate_new_1,
        candidate_new_2: candidate_new_2,
        candidate_new_3: candidate_new_3,
        job_id: job_id
      }
    end

    test "reorders successfully when a candidate is moved up in the same column", %{
      candidate_new_1: candidate_new_1,
      candidate_new_2: candidate_new_2,
      candidate_new_3: candidate_new_3,
      job_id: job_id
    } do
      assert {:ok,
              %{
                move_all_up_by_one: "1 record(s) updated",
                update_candidate: %Candidate{},
                move_all_down_by_one: "All records updated"
              }} = Candidates.reorder_candidates(job_id, candidate_new_2.id, :new, :new, 1)

      assert %{status: :new, position: 2} = Repo.get!(Candidate, candidate_new_1.id)
      assert %{status: :new, position: 1} = Repo.get!(Candidate, candidate_new_2.id)
      assert %{status: :new, position: 3} = Repo.get!(Candidate, candidate_new_3.id)
    end

    test "reorders successfully when a candidate is moved down in the same column", %{
      candidate_new_1: candidate_new_1,
      candidate_new_2: candidate_new_2,
      candidate_new_3: candidate_new_3,
      job_id: job_id
    } do
      assert {:ok,
              %{
                move_all_up_by_one: "2 record(s) updated",
                update_candidate: %Candidate{},
                move_all_down_by_one: "All records updated"
              }} = Candidates.reorder_candidates(job_id, candidate_new_2.id, :new, :new, 3)

      assert %{status: :new, position: 1} = Repo.get!(Candidate, candidate_new_1.id)
      assert %{status: :new, position: 3} = Repo.get!(Candidate, candidate_new_2.id)
      assert %{status: :new, position: 2} = Repo.get!(Candidate, candidate_new_3.id)
    end

    test "reorders successfully when a candidate is moved to a different column", %{
      job_id: job_id,
      candidate_new_1: candidate_new_1,
      candidate_new_2: candidate_new_2,
      candidate_new_3: candidate_new_3
    } do
      candidate_interview_1 =
        candidate_fixture(%{job_id: job_id, status: :interview, position: 1})

      candidate_interview_2 =
        candidate_fixture(%{job_id: job_id, status: :interview, position: 2})

      candidate_interview_3 =
        candidate_fixture(%{job_id: job_id, status: :interview, position: 3})

      assert {:ok,
              %{
                move_all_up_by_one: "1 record(s) updated",
                update_candidate: %Candidate{},
                move_all_down_by_one: "All records updated"
              }} =
               Candidates.reorder_candidates(job_id, candidate_new_2.id, :new, :interview, 2)

      assert %{status: :new, position: 1} = Repo.get!(Candidate, candidate_new_1.id)
      assert %{status: :interview, position: 2} = Repo.get!(Candidate, candidate_new_2.id)
      assert %{status: :new, position: 2} = Repo.get!(Candidate, candidate_new_3.id)
      assert %{status: :interview, position: 1} = Repo.get!(Candidate, candidate_interview_1.id)
      assert %{status: :interview, position: 3} = Repo.get!(Candidate, candidate_interview_2.id)
      assert %{status: :interview, position: 4} = Repo.get!(Candidate, candidate_interview_3.id)
    end
  end
end
