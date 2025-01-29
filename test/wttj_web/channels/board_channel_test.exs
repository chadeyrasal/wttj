defmodule WttjWeb.BoardChannelTest do
  use WttjWeb.ChannelCase

  import Wttj.{CandidatesFixtures, JobsFixtures}

  alias Wttj.Candidates
  alias Wttj.Candidates.CandidateStatuses
  alias WttjWeb.BoardSocket

  @new_status CandidateStatuses.new()

  setup do
    job = job_fixture()
    candidate_1 = candidate_fixture(%{job_id: job.id, status: @new_status, position: 0})
    candidate_2 = candidate_fixture(%{job_id: job.id, status: @new_status, position: 1})
    candidate_3 = candidate_fixture(%{job_id: job.id, status: @new_status, position: 2})

    %{job: job, candidate_1: candidate_1, candidate_2: candidate_2, candidate_3: candidate_3}

    {:ok, socket} = connect(BoardSocket, %{"token" => "1234567890"})
    {:ok, _, socket} = subscribe_and_join(socket, "board:#{job.id}")

    %{
      socket: socket,
      job: job,
      candidate_1: candidate_1,
      candidate_2: candidate_2,
      candidate_3: candidate_3
    }
  end

  describe "handle_id/3" do
    test "successfully handles candidate move", %{
      socket: socket,
      job: job,
      candidate_1: candidate_1
    } do
      message =
        push(socket, "move_candidate", %{
          "jobId" => job.id,
          "candidateId" => candidate_1.id,
          "sourceColumn" => "new",
          "destinationColumn" => "new",
          "position" => 2,
          "version" => 0
        })

      assert_reply(message, :ok, %{candidates: updated_candidates})

      assert %{position: 2, version: 1} =
               Enum.find(updated_candidates, fn candidate -> candidate.id == candidate_1.id end)

      assert_broadcast("move_candidate", %{candidates: ^updated_candidates})
    end

    test "handles version conflict", %{socket: socket, job: job, candidate_1: candidate_1} do
      {:ok, _} = Candidates.update_candidate(candidate_1, %{version: 1})

      message =
        push(socket, "move_candidate", %{
          "jobId" => job.id,
          "candidateId" => candidate_1.id,
          "sourceColumn" => "new",
          "destinationColumn" => "interview",
          "position" => 0,
          "version" => 0
        })

      assert_reply(message, :error, %{current: current_state})

      assert %{status: @new_status, position: 0} =
               Enum.find(current_state, fn candidate -> candidate.id == candidate_1.id end)
    end

    test "handles invalid input", %{socket: socket, job: job, candidate_1: candidate_1} do
      message =
        push(socket, "move_candidate", %{
          "jobId" => job.id,
          "candidateId" => candidate_1.id,
          "sourceColumn" => "new",
          "destinationColumn" => "interview",
          "position" => "first-position",
          "version" => 0
        })

      assert_reply(message, :error, %{current: _current_state})
    end
  end
end
