import { HttpResponse, http } from 'msw'
import { server } from '../test/mocks/setup'
import { getCandidates, getJob, getJobs, reorderCandidates } from './index'

describe('API', () => {
  describe('getJobs', () => {
    it('fetches jobs successfully', async () => {
      const jobs = await getJobs()
      expect(jobs).toEqual([
        { id: '1', name: 'Software Engineer' },
        { id: '2', name: 'Product Manager' },
      ])
    })

    it('handles API errors', async () => {
      server.use(
        http.get('http://localhost:4000/api/jobs', () => {
          return new HttpResponse(null, { status: 500 })
        })
      )

      const jobs = await getJobs()
      expect(jobs).toEqual([])
    })
  })

  describe('getJob', () => {
    it('fetches a single job successfully', async () => {
      const job = await getJob('1')
      expect(job).toEqual({ id: '1', name: 'Software Engineer' })
    })

    it('returns null when jobId is undefined', async () => {
      const job = await getJob(undefined)
      expect(job).toBeNull()
    })

    it('handles API errors', async () => {
      server.use(
        http.get('http://localhost:4000/api/jobs/:jobId', () => {
          return new HttpResponse(null, { status: 500 })
        })
      )

      const job = await getJob('1')
      expect(job).toBeNull()
    })
  })

  describe('getCandidates', () => {
    it('fetches candidates successfully', async () => {
      const candidates = await getCandidates('1')
      expect(candidates).toEqual([
        { id: '1', email: 'test@example.com', status: 'new', position: 0 },
        { id: '2', email: 'test2@example.com', status: 'interview', position: 0 },
      ])
    })

    it('returns an empty array when jobId is undefined', async () => {
      const candidates = await getCandidates(undefined)
      expect(candidates).toEqual([])
    })

    it('handles API errors', async () => {
      server.use(
        http.get('http://localhost:4000/api/jobs/:jobId/candidates', () => {
          return new HttpResponse(null, { status: 500 })
        })
      )

      const candidates = await getCandidates('1')
      expect(candidates).toEqual([])
    })
  })

  describe('reorderCandidates', () => {
    it('reorders candidates successfully', async () => {
      const candidates = await reorderCandidates({
        jobId: '1',
        candidateId: '1',
        sourceColumn: 'new',
        destinationColumn: 'interview',
        position: 1,
      })
      expect(candidates).toEqual([
        { id: '1', email: 'test@example.com', status: 'interview', position: 1 },
        { id: '2', email: 'test2@example.com', status: 'interview', position: 0 },
      ])
    })

    it('returns an empty array when the mutation fails', async () => {
      server.use(
        http.put('http://localhost:4000/api/jobs/:jobId/candidates/reorder', () => {
          return new HttpResponse(null, {
            status: 500,
            statusText: 'Internal Server Error',
          })
        })
      )

      const candidates = await reorderCandidates({
        jobId: '1',
        candidateId: '1',
        sourceColumn: 'new',
        destinationColumn: 'interview',
        position: 1,
      })
      expect(candidates).toEqual([])
    })
  })
})
