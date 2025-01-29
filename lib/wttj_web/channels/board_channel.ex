defmodule WttjWeb.BoardChannel do
  use WttjWeb, :channel

  require Logger

  alias Wttj.Candidates

  def join("board:" <> job_id, _params, socket) do
    {:ok, assign(socket, :job_id, job_id)}
  end

  def handle_in(
        "move_candidate",
        %{
          "jobId" => job_id,
          "candidateId" => candidate_id,
          "sourceColumn" => source_column,
          "destinationColumn" => destination_column,
          "position" => new_position,
          "version" => client_version
        },
        socket
      ) do
    %{
      job_id: job_id,
      candidate_id: candidate_id,
      source_column: source_column,
      destination_column: destination_column,
      position: new_position,
      client_version: client_version
    }
    |> Candidates.move_candidate()
    |> case do
      {:ok, updated_candidates} ->
        broadcast_from!(socket, "move_candidate", %{candidates: updated_candidates})
        {:reply, {:ok, %{candidates: updated_candidates}}, socket}

      {:error, current_state} ->
        {:reply, {:error, %{reason: %{current: current_state}}}, socket}
    end
  end
end
