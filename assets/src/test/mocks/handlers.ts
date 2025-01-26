import { http, HttpResponse } from 'msw'

export const handlers = [
  http.get('http://localhost:4000/api/jobs', async ({ request }) => {
    if (request.headers.get('x-test-error')) {
      return HttpResponse.error()
    }

    return HttpResponse.json({
      data: [
        { id: '1', name: 'Software Engineer' },
        { id: '2', name: 'Product Manager' },
      ],
    })
  }),

  http.get('http://localhost:4000/api/jobs/:jobId', ({ params }) => {
    return HttpResponse.json({
      data: { id: params.jobId, name: 'Software Engineer' },
    })
  }),

  http.get('http://localhost:4000/api/jobs/:jobId/candidates', () => {
    return HttpResponse.json({
      data: [
        { id: '1', email: 'test@example.com', status: 'new', position: 0 },
        { id: '2', email: 'test2@example.com', status: 'interview', position: 0 },
      ],
    })
  }),

  http.put('http://localhost:4000/api/jobs/:jobId/candidates/reorder', ({ request }) => {
    if (request.headers.get('x-test-error')) {
      return new HttpResponse(null, {
        status: 500,
        statusText: 'Internal Server Error',
      })
    }

    return HttpResponse.json({
      data: [
        { id: '1', email: 'test@example.com', status: 'interview', position: 1 },
        { id: '2', email: 'test2@example.com', status: 'interview', position: 0 },
      ],
    })
  }),
]
