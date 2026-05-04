/**
 * Page: User Manager - Quản lý danh sách tài khoản.
 */
import { useState, useEffect } from 'react'
import { adminApi } from '../api/client'
import DataTable from '../components/DataTable'

function UserManager() {
  const [users, setUsers] = useState([])

  useEffect(() => {
    adminApi.getUsers()
      .then((data) => setUsers(data.users || []))
      .catch(() => console.warn('Không thể lấy danh sách users'))
  }, [])

  const columns = [
    { key: 'id', label: 'ID' },
    { key: 'username', label: 'Tên đăng nhập' },
    { key: 'email', label: 'Email' },
    { key: 'created_at', label: 'Ngày tạo' },
  ]

  return (
    <div>
      <h2>👥 Quản lý Tài khoản</h2>
      <DataTable columns={columns} data={users} />
    </div>
  )
}

export default UserManager
