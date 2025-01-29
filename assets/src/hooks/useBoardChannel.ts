import { Socket, Channel } from 'phoenix'
import { useState, useEffect } from 'react'
import { useAuth } from './useAuth'
import { useQueryClient } from 'react-query'
import { Candidate, ReorderVariables } from '../api'

interface PhoenixError {
  reason?: {
    current?: Candidate[]
    message?: string
  }
}

export const useBoardChannel = (jobId: string) => {
  const [channel, setChannel] = useState<Channel | null>(null)
  const { token } = useAuth()
  const queryClient = useQueryClient()

  useEffect(() => {
    const socket = new Socket('http://localhost:4000/board', { params: { token } })
    socket.connect()

    const channel = socket.channel(`board:${jobId}`)

    channel.on('move_candidate', (updatedCandidates: Candidate[]) => {
      queryClient.setQueryData(['candidates'], updatedCandidates)
    })

    channel
      .join()
      .receive('ok', () => setChannel(channel))
      .receive('error', () => console.error('Failed to join board channel'))

    return () => {
      channel.leave()
      socket.disconnect()
    }
  }, [jobId, token, queryClient])

  const moveCandidate = async (variables: ReorderVariables) => {
    if (!channel) throw new Error('Channel not connected')

    try {
      const response = await channel.push('move_candidate', {
        jobId: variables.jobId,
        candidateId: variables.candidateId,
        sourceColumn: variables.sourceColumn,
        destinationColumn: variables.destinationColumn,
        position: variables.position,
        version: variables.version,
      })

      return response
    } catch (error) {
      if ((error as PhoenixError).reason?.current) {
        queryClient.setQueryData(['candidates'], (error as PhoenixError).reason?.current)
        throw new Error('Position changed by another user')
      }
      throw error
    }
  }

  return { moveCandidate, channel }
}
