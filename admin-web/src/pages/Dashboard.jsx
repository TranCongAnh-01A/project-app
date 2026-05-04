/**
 * Page: Dashboard - Theo dõi CPU, RAM, dung lượng ổ cứng Server.
 * Gọi API /admin/stats để lấy metrics realtime.
 */
import { useState, useEffect } from 'react'
import { adminApi } from '../api/client'

function Dashboard() {
  const [stats, setStats] = useState({ cpu: 0, ram: 0, disk: 0 })

  useEffect(() => {
    adminApi.getStats()
      .then(setStats)
      .catch(() => console.warn('Không thể lấy stats từ server'))
  }, [])

  return (
    <div>
      <h2>📊 Dashboard</h2>
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: '1rem' }}>
        <StatCard label="CPU" value={`${stats.cpu}%`} />
        <StatCard label="RAM" value={`${stats.ram}%`} />
        <StatCard label="Disk" value={`${stats.disk}%`} />
      </div>
    </div>
  )
}

function StatCard({ label, value }) {
  return (
    <div style={{ padding: '1.5rem', border: '1px solid #ddd', borderRadius: '8px' }}>
      <p style={{ margin: 0, color: '#888', fontSize: '0.9rem' }}>{label}</p>
      <p style={{ margin: '0.5rem 0 0', fontSize: '2rem', fontWeight: 'bold' }}>{value}</p>
    </div>
  )
}

export default Dashboard
