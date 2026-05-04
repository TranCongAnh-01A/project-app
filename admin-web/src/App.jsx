import { useState } from 'react'
import Dashboard from './pages/Dashboard'
import ContentManager from './pages/ContentManager'
import UserManager from './pages/UserManager'

const PAGES = {
  dashboard: { label: '📊 Dashboard', component: Dashboard },
  content: { label: '📁 Nội dung', component: ContentManager },
  users: { label: '👥 Tài khoản', component: UserManager },
}

function App() {
  const [activePage, setActivePage] = useState('dashboard')
  const ActiveComponent = PAGES[activePage].component

  return (
    <div style={{ display: 'flex', minHeight: '100vh', fontFamily: 'system-ui' }}>
      {/* Sidebar */}
      <nav style={{ width: 220, background: '#1a1a2e', color: '#fff', padding: '1.5rem 0' }}>
        <h3 style={{ padding: '0 1rem', margin: '0 0 1.5rem' }}>🗄️ PMKA Admin</h3>
        {Object.entries(PAGES).map(([key, page]) => (
          <button
            key={key}
            onClick={() => setActivePage(key)}
            style={{
              display: 'block',
              width: '100%',
              padding: '0.75rem 1rem',
              border: 'none',
              background: activePage === key ? '#16213e' : 'transparent',
              color: '#fff',
              textAlign: 'left',
              cursor: 'pointer',
              fontSize: '0.95rem',
            }}
          >
            {page.label}
          </button>
        ))}
      </nav>

      {/* Main Content */}
      <main style={{ flex: 1, padding: '2rem' }}>
        <ActiveComponent />
      </main>
    </div>
  )
}

export default App
