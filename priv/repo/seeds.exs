{:ok, job} = Wttj.Jobs.create_job(%{name: "Full Stack Developer"})

_candidate =
  Wttj.Candidates.create_candidate(%{job_id: job.id, email: "user1@wttj.co", position: 0})

_candidate =
  Wttj.Candidates.create_candidate(%{job_id: job.id, email: "user2@wttj.co", position: 1})

_candidate =
  Wttj.Candidates.create_candidate(%{
    job_id: job.id,
    email: "user3@wttj.co",
    position: 0,
    status: Wttj.Candidates.CandidateStatuses.interview()
  })

_candidate =
  Wttj.Candidates.create_candidate(%{
    job_id: job.id,
    email: "user4@wttj.co",
    position: 0,
    status: Wttj.Candidates.CandidateStatuses.rejected()
  })

_candidate =
  Wttj.Candidates.create_candidate(%{
    job_id: job.id,
    email: "user5@wttj.co",
    position: 1,
    status: Wttj.Candidates.CandidateStatuses.rejected()
  })
