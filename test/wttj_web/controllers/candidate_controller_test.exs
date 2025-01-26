defmodule WttjWeb.CandidateControllerTest do
  use WttjWeb.ConnCase

  import ExUnit.CaptureLog

  import Wttj.JobsFixtures
  import Wttj.CandidatesFixtures

  alias Wttj.Candidates.{Candidate, CandidateStatuses}

  @update_attrs %{
    position: 43,
    status: CandidateStatuses.interview()
  }
  @invalid_attrs %{position: nil, status: nil, email: nil}
  @interview_status CandidateStatuses.interview() |> Atom.to_string()
  @hired_status CandidateStatuses.hired() |> Atom.to_string()

  setup %{conn: conn} do
    job = job_fixture()
    {:ok, conn: put_req_header(conn, "accept", "application/json"), job: job}
  end

  describe "index/2" do
    test "lists all candidates", %{conn: conn, job: job} do
      conn = get(conn, ~p"/api/jobs/#{job}/candidates")
      assert json_response(conn, 200)["data"] == []
    end
  end

  describe "update/2" do
    setup [:create_candidate]

    test "renders candidate when data is valid", %{
      conn: conn,
      job: job,
      candidate: %Candidate{id: id} = candidate
    } do
      email = unique_user_email()
      attrs = Map.put(@update_attrs, :email, email)
      conn = put(conn, ~p"/api/jobs/#{job}/candidates/#{candidate}", candidate: attrs)
      assert %{"id" => ^id} = json_response(conn, 200)["data"]

      conn = get(conn, ~p"/api/jobs/#{job}/candidates/#{id}")

      assert %{
               "id" => ^id,
               "email" => ^email,
               "position" => 43,
               "status" => "interview"
             } = json_response(conn, 200)["data"]
    end

    test "renders errors when data is invalid", %{conn: conn, candidate: candidate, job: job} do
      conn = put(conn, ~p"/api/jobs/#{job}/candidates/#{candidate}", candidate: @invalid_attrs)
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "reorder/2" do
    setup do
      job = job_fixture()
      candidate_1 = candidate_fixture(%{job_id: job.id, position: 1, status: @interview_status})
      candidate_2 = candidate_fixture(%{job_id: job.id, position: 2, status: @interview_status})

      %{job: job, candidate_1: candidate_1, candidate_2: candidate_2}
    end

    test "renders updated list of candidates when reordering candidates worked as expected", %{
      conn: conn,
      job: job,
      candidate_1: candidate_1,
      candidate_2: candidate_2
    } do
      conn =
        put(conn, ~p"/api/jobs/#{job}/candidates/reorder", %{
          "job_id" => job.id,
          "candidate_id" => candidate_1.id,
          "source_column" => @interview_status,
          "destination_column" => @hired_status,
          "position" => "1"
        })

      assert json_response(conn, 200)["data"] == [
               %{
                 "email" => candidate_1.email,
                 "id" => candidate_1.id,
                 "status" => @hired_status,
                 "position" => candidate_1.position
               },
               %{
                 "email" => candidate_2.email,
                 "id" => candidate_2.id,
                 "status" => Atom.to_string(candidate_2.status),
                 "position" => candidate_2.position - 1
               }
             ]
    end

    test "renders error when the data is invalid", %{
      conn: conn,
      job: job,
      candidate_1: candidate_1
    } do
      capture_log(fn ->
        conn =
          put(conn, ~p"/api/jobs/#{job}/candidates/reorder", %{
            "job_id" => job.id,
            "candidate_id" => candidate_1.id,
            "source_column" => @interview_status,
            "destination_column" => "invalid_status",
            "position" => "1"
          })

        assert json_response(conn, 422)["errors"] != %{}
      end)
    end
  end

  defp create_candidate(%{job: job}) do
    candidate = candidate_fixture(%{job_id: job.id})
    %{candidate: candidate}
  end
end
