/**
 * API Client: Gọi các API admin từ backend.
 * Tập trung mọi HTTP request vào một nơi để dễ quản lý base URL và auth headers.
 */
const API_BASE = import.meta.env.VITE_API_URL || 'http://localhost:8000'

async function request(endpoint, options = {}) {
  try {
    const response = await fetch(`${API_BASE}${endpoint}`, {
      headers: { 'Content-Type': 'application/json', ...options.headers },
      ...options,
    })

    if (!response.ok) {
      throw new Error(`API Error: ${response.status} ${response.statusText}`)
    }

    return await response.json()
  } catch (error) {
    console.error(`[API] ${endpoint}:`, error)
    throw error
  }
}

// ── Admin APIs ──
export const adminApi = {
  getStats: () => request('/api/v1/admin/stats'),
  getUsers: () => request('/api/v1/admin/users'),
  deleteContent: (id) => request(`/api/v1/admin/content/${id}`, { method: 'DELETE' }),
}

// ── Health Check ──
export const healthCheck = () => request('/health')
