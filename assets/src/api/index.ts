type Job = {
  id: string
  name: string
}

export type Candidate = {
  id: number
  email: string
  status: 'new' | 'interview' | 'hired' | 'rejected'
  position: number
  version: number
}

export type ReorderVariables = {
  jobId: string
  candidateId: string
  sourceColumn: string
  destinationColumn: string
  position: number
  version: number
}

export const getJobs = async (): Promise<Job[]> => {
  try {
    const response = await fetch(`http://localhost:4000/api/jobs`)
    if (!response.ok) {
      return []
    }
    const { data } = await response.json()
    return data
  } catch (error) {
    console.error('Error fetching jobs:', error)
    return []
  }
}

export const getJob = async (jobId?: string): Promise<Job | null> => {
  if (!jobId) return null
  try {
    const response = await fetch(`http://localhost:4000/api/jobs/${jobId}`)
    if (!response.ok) {
      return null
    }
    const { data } = await response.json()
    return data
  } catch (error) {
    console.error('Error fetching job:', error)
    return null
  }
}

export const getCandidates = async (jobId?: string): Promise<Candidate[]> => {
  if (!jobId) return []
  try {
    const response = await fetch(`http://localhost:4000/api/jobs/${jobId}/candidates`)
    if (!response.ok) {
      return []
    }
    const { data } = await response.json()
    return data
  } catch (error) {
    console.error('Error fetching candidates:', error)
    return []
  }
}

export const reorderCandidates = async ({
  jobId,
  candidateId,
  sourceColumn,
  destinationColumn,
  position,
}: ReorderVariables): Promise<Candidate[]> => {
  try {
    const response = await fetch(`http://localhost:4000/api/jobs/${jobId}/candidates/reorder`, {
      method: 'PUT',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        job_id: jobId,
        candidate_id: candidateId,
        source_column: sourceColumn,
        destination_column: destinationColumn,
        position,
      }),
    })

    if (!response.ok) {
      return []
    }

    const { data } = await response.json()
    return data
  } catch (error) {
    console.error('Error reordering candidates:', error)
    return []
  }
}
