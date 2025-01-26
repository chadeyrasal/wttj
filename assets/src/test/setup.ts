import { beforeAll, afterEach, afterAll } from 'vitest'
import { cleanup } from '@testing-library/react'
import '@testing-library/jest-dom'
import { server } from './mocks/setup'

// Enable request interception
beforeAll(() => {
  server.listen({ onUnhandledRequest: 'error' })
})

// Reset handlers between tests
afterEach(() => {
  server.resetHandlers()
  cleanup()
})

// Clean up after tests
afterAll(() => {
  server.close()
})
