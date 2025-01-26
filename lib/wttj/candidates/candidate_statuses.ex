defmodule Wttj.Candidates.CandidateStatuses do
  @statuses [:new, :interview, :rejected, :hired]

  def statuses, do: @statuses

  @statuses_as_strings Enum.map(@statuses, &to_string/1)
  def is_valid_string_status?(status), do: Enum.member?(@statuses_as_strings, status)

  def new, do: :new
  def interview, do: :interview
  def rejected, do: :rejected
  def hired, do: :hired
end
