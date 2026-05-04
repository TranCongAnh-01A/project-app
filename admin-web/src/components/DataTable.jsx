/**
 * Component: Bảng dữ liệu dùng chung cho Dashboard.
 * Nhận props: columns (tiêu đề cột) và data (mảng dữ liệu).
 */
function DataTable({ columns = [], data = [] }) {
  if (data.length === 0) {
    return <p style={{ color: '#888' }}>Chưa có dữ liệu.</p>
  }

  return (
    <table style={{ width: '100%', borderCollapse: 'collapse' }}>
      <thead>
        <tr>
          {columns.map((col) => (
            <th key={col.key} style={{ textAlign: 'left', padding: '8px', borderBottom: '2px solid #ddd' }}>
              {col.label}
            </th>
          ))}
        </tr>
      </thead>
      <tbody>
        {data.map((row, i) => (
          <tr key={i}>
            {columns.map((col) => (
              <td key={col.key} style={{ padding: '8px', borderBottom: '1px solid #eee' }}>
                {row[col.key]}
              </td>
            ))}
          </tr>
        ))}
      </tbody>
    </table>
  )
}

export default DataTable
