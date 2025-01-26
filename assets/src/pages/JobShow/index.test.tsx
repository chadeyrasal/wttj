import { render, screen } from '@testing-library/react'
import { QueryClient, QueryClientProvider } from 'react-query'
import JobShow from './index'

vi.mock('@hello-pangea/dnd', () => ({
  DragDropContext: ({
    children,
    onDragEnd,
  }: {
    children: React.ReactNode
    onDragEnd: (result: any) => void
  }) => {
    ;(global as any).mockOnDragEnd = onDragEnd
    return children
  },
  Droppable: ({ children }: any) => children({ innerRef: null, droppableProps: {} }),
  Draggable: ({ children }: any) =>
    children({ innerRef: null, draggableProps: {}, dragHandleProps: {} }),
}))

vi.mock('../../hooks', () => ({
  useJob: () => ({
    job: {
      id: '1',
      name: 'Software Engineer',
    },
    isLoading: false,
    error: null,
  }),
  useCandidates: () => ({
    candidates: [
      { id: 1, email: 'test@example.com', status: 'new', position: 0 },
      { id: 2, email: 'test2@example.com', status: 'interview', position: 0 },
    ],
    isLoading: false,
    error: null,
  }),
}))

vi.mock('react-router-dom', () => ({
  useParams: () => ({ jobId: '1' }),
}))

const mockMutate = vi.fn()

vi.mock('react-query', async () => {
  const actual = await vi.importActual('react-query')
  return {
    ...actual,
    useMutation: () => ({
      mutate: mockMutate,
      isLoading: false,
      error: null,
    }),
    useQueryClient: () => ({
      invalidateQueries: vi.fn(),
    }),
  }
})

const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      retry: false,
    },
  },
})

const renderJobShow = () => {
  return render(
    <QueryClientProvider client={queryClient}>
      <JobShow />
    </QueryClientProvider>
  )
}

describe('JobShow', () => {
  it('renders job name', async () => {
    renderJobShow()
    expect(await screen.findByText('Software Engineer')).toBeInTheDocument()
  })

  it('renders all status columns', () => {
    renderJobShow()
    expect(screen.getByText('new')).toBeInTheDocument()
    expect(screen.getByText('interview')).toBeInTheDocument()
    expect(screen.getByText('hired')).toBeInTheDocument()
    expect(screen.getByText('rejected')).toBeInTheDocument()
  })

  it('renders candidates in correct columns', async () => {
    renderJobShow()
    const newCandidate = await screen.findByText('test@example.com')
    const interviewCandidate = await screen.findByText('test2@example.com')

    expect(newCandidate).toBeInTheDocument()
    expect(interviewCandidate).toBeInTheDocument()
  })

  it('shows correct candidate count in badges', async () => {
    renderJobShow()

    const newBadge = screen.getByTestId('new')
    const interviewBadge = screen.getByTestId('interview')

    expect(newBadge).toHaveTextContent('1')
    expect(interviewBadge).toHaveTextContent('1')
  })

  it('handles candidate reordering', async () => {
    renderJobShow()

    // Simulate drag end using the stored callback
    const dropResult = {
      source: { droppableId: 'new', index: 0 },
      destination: { droppableId: 'interview', index: 0 },
      draggableId: '1',
    }

    ;(global as any).mockOnDragEnd(dropResult)

    expect(mockMutate).toHaveBeenCalledWith({
      jobId: '1',
      candidateId: '1',
      sourceColumn: 'new',
      destinationColumn: 'interview',
      position: 0,
    })
  })
})
