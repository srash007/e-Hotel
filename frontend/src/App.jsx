import { useState } from 'react'
import CustomerPage from './pages/CustomerPage'
import EmployeePage from './pages/EmployeePage'
import AdminPage from './pages/AdminPage'
import ViewsPage from './pages/ViewsPage'

const PAGES = [
  { label: '🏨 Find a Room', component: <CustomerPage /> },
  { label: '👷 Employee', component: <EmployeePage /> },
  { label: '⚙️ Admin', component: <AdminPage /> },
  { label: '📊 SQL Views', component: <ViewsPage /> },
]

export default function App() {
  const [current, setCurrent] = useState(0)

  return (
    <>
      <nav>
        <span className="logo">🏨 e-Hotels</span>
        {PAGES.map((p, i) => (
          <button
            key={p.label}
            className={current === i ? 'active' : ''}
            onClick={() => setCurrent(i)}
          >
            {p.label}
          </button>
        ))}
      </nav>
      {PAGES[current].component}
    </>
  )
}
