import { Box } from '@welcome-ui/box'
import { Flex } from '@welcome-ui/flex'
import { Link } from '@welcome-ui/link'
import { Link as RouterLink, Outlet } from 'react-router-dom'
import { useAuth } from '../../hooks/useAuth'

function Layout() {
  const { isAuthenticated, logout } = useAuth()

  return (
    <Box backgroundColor="beige-20" h="100vh">
      <Box backgroundColor="black" p={20}>
        <Flex>
          <Link as={RouterLink} to="/" color="white">
            <div>Jobs</div>
          </Link>
          <Box display="flex" justifyContent="flex-end" p="md">
            {isAuthenticated && <button onClick={logout}>Logout</button>}
          </Box>
        </Flex>
      </Box>

      <Box>
        <Outlet />
      </Box>
    </Box>
  )
}

export default Layout
