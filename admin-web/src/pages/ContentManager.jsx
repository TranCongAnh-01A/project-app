/**
 * Page: Content Manager - Quản lý/Xóa nội dung người dùng đã lưu.
 */
import { useState, useEffect } from 'react'
import { adminApi } from '../api/client'
import DataTable from '../components/DataTable'

function ContentManager() {
  const [contents, setContents] = useState([])

  const columns = [
    { key: 'id', label: 'ID' },
    { key: 'title', label: 'Tiêu đề' },
    { key: 'type', label: 'Loại' },
    { key: 'user', label: 'Người dùng' },
    { key: 'size', label: 'Dung lượng' },
  ]

  return (
    <div>
      <h2>📁 Quản lý Nội dung</h2>
      <DataTable columns={columns} data={contents} />
    </div>
  )
}

export default ContentManager
