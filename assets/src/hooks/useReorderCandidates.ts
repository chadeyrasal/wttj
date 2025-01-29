import { useMutation, useQueryClient } from 'react-query'
import { useBoardChannel } from './useBoardChannel'
import { ReorderVariables } from '../api'

export const useReorderCandidates = (jobId: string) => {
  const queryClient = useQueryClient()
  const { moveCandidate } = useBoardChannel(jobId)

  return useMutation({
    mutationFn: (variables: ReorderVariables) => moveCandidate(variables),
    onError: () => {
      window.alert('Position was updated by another user')
    },
    onSettled: () => {
      queryClient.invalidateQueries(['candidates'])
    },
  })
}
