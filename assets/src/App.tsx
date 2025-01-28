import { createTheme, WuiProvider } from '@welcome-ui/core'
import { createBrowserRouter, RouterProvider, useNavigate } from 'react-router-dom'
import JobIndex from './pages/JobIndex'
import Layout from './components/Layout'
import JobShow from './pages/JobShow'
import { AuthProvider } from './AuthContext'
import Login from './pages/Login/login'
import { useEffect } from 'react'
import { useAuth } from './hooks/useAuth'

const theme = createTheme()

const ProtectedRoute = ({ children }: { children: React.ReactNode }) => {
  const { isAuthenticated, loading } = useAuth()
  const navigate = useNavigate()

  useEffect(() => {
    if (!loading && !isAuthenticated) {
      navigate('/login')
    }
  }, [isAuthenticated, loading, navigate])

  if (loading) return <div>Loading...</div>

  return isAuthenticated ? <>{children}</> : null
}

const router = createBrowserRouter([
  {
    path: '/',
    element: <Layout />,
    children: [
      {
        path: '',
        element: (
          <ProtectedRoute>
            <JobIndex />
          </ProtectedRoute>
        ),
      },
      {
        path: 'jobs/:jobId',
        element: (
          <ProtectedRoute>
            <JobShow />
          </ProtectedRoute>
        ),
      },
      { path: 'login', element: <Login /> },
    ],
  },
])

function App() {
  return (
    <AuthProvider>
      <WuiProvider theme={theme}>
        <RouterProvider router={router} />
      </WuiProvider>
    </AuthProvider>
  )
}

export default App
