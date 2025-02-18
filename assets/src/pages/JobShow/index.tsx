import { useParams } from 'react-router-dom'
import { DragDropContext, Droppable, Draggable, DropResult } from '@hello-pangea/dnd'
import { useJob, useCandidates } from '../../hooks'
import { Text } from '@welcome-ui/text'
import { Flex } from '@welcome-ui/flex'
import { Box } from '@welcome-ui/box'
import { useMemo } from 'react'
import { Candidate } from '../../api'
import CandidateCard from '../../components/Candidate'
import { Badge } from '@welcome-ui/badge'
import { useReorderCandidates } from '../../hooks/useReorderCandidates'

type Statuses = 'new' | 'interview' | 'hired' | 'rejected'
const COLUMNS: Statuses[] = ['new', 'interview', 'hired', 'rejected']

interface SortedCandidates {
  new?: Candidate[]
  interview?: Candidate[]
  hired?: Candidate[]
  rejected?: Candidate[]
}

function JobShow() {
  const { jobId } = useParams()
  const { job } = useJob(jobId)
  const { candidates } = useCandidates(jobId!)
  const { mutate } = useReorderCandidates(jobId!)

  const sortedCandidates = useMemo(() => {
    if (!candidates) return {}

    return candidates.reduce<SortedCandidates>((acc, c: Candidate) => {
      acc[c.status] = [...(acc[c.status] || []), c].sort((a, b) => a.position - b.position)
      return acc
    }, {})
  }, [candidates])

  const onDragEnd = (result: DropResult) => {
    const { source, destination, draggableId } = result
    if (!destination) return

    mutate({
      jobId: jobId!,
      candidateId: draggableId,
      sourceColumn: source.droppableId,
      destinationColumn: destination.droppableId,
      position: destination.index,
      version: candidates?.find(candidate => candidate.id.toString() === draggableId)?.version || 0,
    })
  }

  return (
    <DragDropContext onDragEnd={onDragEnd}>
      <Box backgroundColor="neutral-70" p={20} alignItems="center">
        <Text variant="h5" color="white" m={0}>
          {job?.name}
        </Text>
      </Box>

      <Box p={20}>
        <Flex gap={10}>
          {COLUMNS.map(column => (
            <Box
              w={300}
              border={1}
              backgroundColor="white"
              borderColor="neutral-30"
              borderRadius="md"
              overflow="hidden"
              key={column}
            >
              <Flex
                p={10}
                borderBottom={1}
                borderColor="neutral-30"
                alignItems="center"
                justify="space-between"
              >
                <Text color="black" m={0} textTransform="capitalize">
                  {column}
                </Text>
                <Badge data-testid={`${column}`}>{(sortedCandidates[column] || []).length}</Badge>
              </Flex>

              <Droppable droppableId={column}>
                {provided => (
                  <Flex
                    direction="column"
                    p={10}
                    pb={0}
                    ref={provided.innerRef}
                    {...provided.droppableProps}
                  >
                    {sortedCandidates[column]?.map((candidate: Candidate, index: number) => (
                      <Draggable
                        key={candidate.id}
                        draggableId={candidate.id.toString()}
                        index={index}
                      >
                        {provided => (
                          <div
                            ref={provided.innerRef}
                            {...provided.draggableProps}
                            {...provided.dragHandleProps}
                          >
                            <CandidateCard key={candidate.id} candidate={candidate} />
                          </div>
                        )}
                      </Draggable>
                    ))}
                    {provided.placeholder}
                  </Flex>
                )}
              </Droppable>
            </Box>
          ))}
        </Flex>
      </Box>
    </DragDropContext>
  )
}

export default JobShow
