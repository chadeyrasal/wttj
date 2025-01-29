defmodule Wttj.CandidatesTest do
  alias Wttj.CandidatesFixtures
  use Wttj.DataCase

  import ExUnit.CaptureLog

  import Wttj.CandidatesFixtures
  import Wttj.JobsFixtures

  alias Ecto.Changeset

  alias Wttj.{Candidates, Repo}
  alias Wttj.Candidates.{Candidate, CandidateStatuses}

  @invalid_attrs %{position: nil, status: nil, email: nil}
  @new_status CandidateStatuses.new()
  @interview_status CandidateStatuses.interview()
  @rejected_status CandidateStatuses.rejected()

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
      update_attrs = %{position: 43, status: @rejected_status, email: email}

      assert {:ok, %Candidate{position: 43, status: @rejected_status, email: ^email}} =
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

  describe "move_candidate/1" do
    setup do
      %{id: job_id} = job_fixture()

      candidate = CandidatesFixtures.candidate_fixture(%{job_id: job_id})

      %{id: candidate_id, status: status, position: position, version: version} =
        CandidatesFixtures.candidate_fixture(%{
          job_id: job_id,
          status: @new_status,
          position: 0,
          version: 1
        })

      %{
        job_id: job_id,
        candidate_id: candidate_id,
        status: status,
        position: position,
        version: version,
        candidate: candidate
      }
    end

    test "returns the updated state when the input is valid and the client version is the same as the version in the database",
         %{
           job_id: job_id,
           candidate_id: candidate_id,
           version: version,
           candidate: %{id: other_candidate_id}
         } do
      assert {:ok,
              [
                %{
                  id: ^candidate_id,
                  job_id: ^job_id,
                  version: 2,
                  status: @interview_status,
                  position: 0
                },
                %{id: ^other_candidate_id}
              ]} =
               Candidates.move_candidate(%{
                 job_id: job_id,
                 candidate_id: candidate_id,
                 client_version: version,
                 source_column: "new",
                 destination_column: "interview",
                 position: 0
               })
    end

    test "returns and logs an error and returns the current state when the input is invalid", %{
      candidate: %{id: other_candidate_id},
      version: version,
      candidate_id: candidate_id,
      status: status,
      position: position,
      job_id: job_id
    } do
      captured_log =
        capture_log(fn ->
          assert {:error,
                  [
                    %{id: ^other_candidate_id},
                    %{id: ^candidate_id, status: ^status, position: ^position, version: ^version}
                  ]} =
                   Candidates.move_candidate(%{
                     job_id: job_id,
                     candidate_id: candidate_id,
                     client_version: 1,
                     source_column: "new",
                     destination_column: "invalid",
                     position: 0
                   })
        end)

      assert captured_log =~ "Invalid input"
    end

    test "returns an error  and returns the current state when the client version is different from the version in the database",
         %{
           candidate: %{id: other_candidate_id},
           version: version,
           candidate_id: candidate_id,
           status: status,
           position: position,
           job_id: job_id
         } do
      assert {:error,
              [
                %{id: ^other_candidate_id},
                %{id: ^candidate_id, status: ^status, position: ^position, version: ^version}
              ]} =
               Candidates.move_candidate(%{
                 job_id: job_id,
                 candidate_id: candidate_id,
                 client_version: 0,
                 source_column: "new",
                 destination_column: "interview",
                 position: 0
               })
    end
  end

  describe "reorder_candidate/1" do
    setup do
      %{id: job_id} = job_fixture()

      candidate_new_1 =
        candidate_fixture(%{job_id: job_id, status: @new_status, position: 1})

      candidate_new_2 =
        candidate_fixture(%{job_id: job_id, status: @new_status, position: 2})

      candidate_new_3 =
        candidate_fixture(%{job_id: job_id, status: @new_status, position: 3})

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
              }} =
               Candidates.reorder_candidates(%{
                 job_id: job_id,
                 candidate_id: candidate_new_2.id,
                 source_column: "new",
                 destination_column: "new",
                 position: 1
               })

      assert %{status: @new_status, position: 2} =
               Repo.get!(Candidate, candidate_new_1.id)

      assert %{status: @new_status, position: 1} =
               Repo.get!(Candidate, candidate_new_2.id)

      assert %{status: @new_status, position: 3} =
               Repo.get!(Candidate, candidate_new_3.id)
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
              }} =
               Candidates.reorder_candidates(%{
                 job_id: job_id,
                 candidate_id: candidate_new_2.id,
                 source_column: "new",
                 destination_column: "new",
                 position: 3
               })

      assert %{status: @new_status, position: 1} =
               Repo.get!(Candidate, candidate_new_1.id)

      assert %{status: @new_status, position: 3} =
               Repo.get!(Candidate, candidate_new_2.id)

      assert %{status: @new_status, position: 2} =
               Repo.get!(Candidate, candidate_new_3.id)
    end

    test "reorders successfully when a candidate is moved to a different column", %{
      job_id: job_id,
      candidate_new_1: candidate_new_1,
      candidate_new_2: candidate_new_2,
      candidate_new_3: candidate_new_3
    } do
      candidate_interview_1 =
        candidate_fixture(%{job_id: job_id, status: @interview_status, position: 1})

      candidate_interview_2 =
        candidate_fixture(%{job_id: job_id, status: @interview_status, position: 2})

      candidate_interview_3 =
        candidate_fixture(%{job_id: job_id, status: @interview_status, position: 3})

      assert {:ok,
              %{
                move_all_up_by_one: "1 record(s) updated",
                update_candidate: %Candidate{},
                move_all_down_by_one: "All records updated"
              }} =
               Candidates.reorder_candidates(%{
                 job_id: job_id,
                 candidate_id: candidate_new_2.id,
                 source_column: "new",
                 destination_column: "interview",
                 position: 2
               })

      assert %{status: @new_status, position: 1} =
               Repo.get!(Candidate, candidate_new_1.id)

      assert %{status: @interview_status, position: 2} =
               Repo.get!(Candidate, candidate_new_2.id)

      assert %{status: @new_status, position: 2} =
               Repo.get!(Candidate, candidate_new_3.id)

      assert %{status: @interview_status, position: 1} =
               Repo.get!(Candidate, candidate_interview_1.id)

      assert %{status: @interview_status, position: 3} =
               Repo.get!(Candidate, candidate_interview_2.id)

      assert %{status: @interview_status, position: 4} =
               Repo.get!(Candidate, candidate_interview_3.id)
    end

    test "returns and logs error when function called with invalid input",
         %{
           job_id: job_id,
           candidate_new_2: candidate_new_2
         } do
      captured_log =
        capture_log(fn ->
          assert {:error, :invalid_input} =
                   Candidates.reorder_candidates(%{
                     job_id: job_id,
                     candidate_id: candidate_new_2.id,
                     source_column: "new",
                     destination_column: "invalid",
                     position: 2
                   })
        end)

      assert captured_log =~ "The following inputs are invalid: destination_column"
    end
  end
end
