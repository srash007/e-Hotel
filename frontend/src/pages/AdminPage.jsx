import { useState, useEffect } from 'react'
import {
  listCustomers, createCustomer, updateCustomer, deleteCustomer,
  listEmployees, createEmployee, updateEmployee, deleteEmployee,
  listHotels, createHotel, updateHotel, deleteHotel,
  listRooms, createRoom, updateRoom, deleteRoom,
  listChains,
} from '../api'

const TABS = ['👤 Customers', '🧑‍💼 Employees', '🏨 Hotels', '🛏 Rooms']

export default function AdminPage() {
  const [tab, setTab] = useState(0)
  const [msg, setMsg] = useState(null)

  function showMsg(type, text) { setMsg({ type, text }); setTimeout(() => setMsg(null), 5000) }

  return (
    <div className="page">
      <h1>⚙️ Administration Panel</h1>
      <p className="page-subtitle">Insert, update, and delete customers, employees, hotels, and rooms.</p>
      {msg && <div className={`alert alert-${msg.type}`}>{msg.text}</div>}
      <div className="tabs">
        {TABS.map((t, i) => (
          <button key={t} className={`tab${tab === i ? ' active' : ''}`} onClick={() => setTab(i)}>{t}</button>
        ))}
      </div>
      {tab === 0 && <CustomersTab showMsg={showMsg} />}
      {tab === 1 && <EmployeesTab showMsg={showMsg} />}
      {tab === 2 && <HotelsTab showMsg={showMsg} />}
      {tab === 3 && <RoomsTab showMsg={showMsg} />}
    </div>
  )
}


function CustomersTab({ showMsg }) {
  const [customers, setCustomers] = useState([])
  const [loading, setLoading] = useState(true)
  const [showCreate, setShowCreate] = useState(false)
  const [editId, setEditId] = useState(null)
  const [form, setForm] = useState({
    full_name: '', street: '', city: '', state: '', country: '', postal_code: '',
    id_type: 'SIN', id_value: ''
  })
  const [editForm, setEditForm] = useState({})

  function set(k, v) { setForm(f => ({ ...f, [k]: v })) }

  async function load() {
    setLoading(true)
    try { setCustomers(await listCustomers()) }
    catch (e) { showMsg('error', e.message) }
    finally { setLoading(false) }
  }

  useEffect(() => { load() }, [])

  async function handleCreate(e) {
    e.preventDefault()
    try {
      const res = await createCustomer(form)
      showMsg('success', `✅ Customer created! ID: ${res.customer_id}`)
      setForm({ full_name: '', street: '', city: '', state: '', country: '', postal_code: '', id_type: 'SIN', id_value: '' })
      setShowCreate(false)
      load()
    } catch (e) { showMsg('error', e.message) }
  }

  async function handleUpdate(e) {
    e.preventDefault()
    const data = Object.fromEntries(Object.entries(editForm).filter(([_, v]) => v !== ''))
    try {
      await updateCustomer(editId, data)
      showMsg('success', `✅ Customer #${editId} updated.`)
      setEditId(null)
      load()
    } catch (e) { showMsg('error', e.message) }
  }

  async function handleDelete(id) {
    if (!window.confirm(`Delete customer #${id}?`)) return
    try {
      await deleteCustomer(id)
      showMsg('success', `✅ Customer #${id} deleted.`)
      load()
    } catch (e) { showMsg('error', e.message) }
  }

  function startEdit(c) {
    setEditId(c.customer_id)
    setEditForm({
      full_name: c.full_name || '', street: c.street || '', city: c.city || '',
      state: c.state || '', country: c.country || '', postal_code: c.postal_code || ''
    })
  }

  if (loading) return <div className="loading-container"><div className="spinner" /><span>Loading…</span></div>

  return (
    <div className="animate-in">
      <div className="card">
        <div className="card-header">
          <h2>👤 Customers <span className="badge">{customers.length}</span></h2>
          <button className="btn btn-success btn-sm" onClick={() => setShowCreate(!showCreate)}>
            {showCreate ? '▲ Hide Form' : '➕ Add Customer'}
          </button>
        </div>

        {showCreate && (
          <form onSubmit={handleCreate} style={{ marginBottom: '1.5rem', padding: '1rem', background: 'var(--border-light)', borderRadius: 'var(--radius-sm)' }}>
            <div className="form-grid">
              <div className="form-group"><label>Full Name *</label>
                <input required value={form.full_name} onChange={e => set('full_name', e.target.value)} placeholder="John Doe" /></div>
              <div className="form-group"><label>Street *</label>
                <input required value={form.street} onChange={e => set('street', e.target.value)} placeholder="123 Main St" /></div>
              <div className="form-group"><label>City *</label>
                <input required value={form.city} onChange={e => set('city', e.target.value)} placeholder="Ottawa" /></div>
              <div className="form-group"><label>State</label>
                <input value={form.state} onChange={e => set('state', e.target.value)} placeholder="Ontario" /></div>
              <div className="form-group"><label>Country *</label>
                <input required value={form.country} onChange={e => set('country', e.target.value)} placeholder="Canada" /></div>
              <div className="form-group"><label>Postal Code</label>
                <input value={form.postal_code} onChange={e => set('postal_code', e.target.value)} placeholder="K1A 0A1" /></div>
              <div className="form-group"><label>ID Type *</label>
                <select value={form.id_type} onChange={e => set('id_type', e.target.value)}>
                  <option value="SSN">SSN</option><option value="SIN">SIN</option>
                  <option value="DRIVER_LICENCE">Driver's Licence</option><option value="PASSPORT">Passport</option>
                </select></div>
              <div className="form-group"><label>ID Value *</label>
                <input required value={form.id_value} onChange={e => set('id_value', e.target.value)} placeholder="123-456-789" /></div>
            </div>
            <button className="btn btn-success" type="submit">➕ Create</button>
          </form>
        )}

        {customers.length === 0 ? <p className="empty">No customers found.</p> : (
          <div className="table-wrap">
            <table>
              <thead>
                <tr>
                  <th>ID</th><th>Name</th><th>City</th><th>Country</th><th>ID Type</th><th>ID Value</th><th>Actions</th>
                </tr>
              </thead>
              <tbody>
                {customers.map(c => (
                  <tr key={c.customer_id}>
                    <td><strong>#{c.customer_id}</strong></td>
                    <td>{c.full_name}</td>
                    <td>{c.city}</td>
                    <td>{c.country}</td>
                    <td><span className="amenity-tag">{c.id_type}</span></td>
                    <td><small>{c.id_value}</small></td>
                    <td>
                      <div className="flex-row" style={{ gap: '0.35rem' }}>
                        <button className="btn btn-warning btn-sm" onClick={() => startEdit(c)}>✏️</button>
                        <button className="btn btn-danger btn-sm" onClick={() => handleDelete(c.customer_id)}>🗑️</button>
                      </div>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </div>

      {/* Inline edit modal */}
      {editId && (
        <div className="modal-overlay" onClick={() => setEditId(null)}>
          <div className="modal" onClick={e => e.stopPropagation()}>
            <h2>✏️ Edit Customer #{editId}</h2>
            <form onSubmit={handleUpdate}>
              <div className="form-grid" style={{ gridTemplateColumns: '1fr 1fr' }}>
                <div className="form-group"><label>Full Name</label>
                  <input value={editForm.full_name} onChange={e => setEditForm(f => ({ ...f, full_name: e.target.value }))} /></div>
                <div className="form-group"><label>Street</label>
                  <input value={editForm.street} onChange={e => setEditForm(f => ({ ...f, street: e.target.value }))} /></div>
                <div className="form-group"><label>City</label>
                  <input value={editForm.city} onChange={e => setEditForm(f => ({ ...f, city: e.target.value }))} /></div>
                <div className="form-group"><label>State</label>
                  <input value={editForm.state} onChange={e => setEditForm(f => ({ ...f, state: e.target.value }))} /></div>
                <div className="form-group"><label>Country</label>
                  <input value={editForm.country} onChange={e => setEditForm(f => ({ ...f, country: e.target.value }))} /></div>
                <div className="form-group"><label>Postal Code</label>
                  <input value={editForm.postal_code} onChange={e => setEditForm(f => ({ ...f, postal_code: e.target.value }))} /></div>
              </div>
              <div className="modal-actions">
                <button className="btn btn-outline" type="button" onClick={() => setEditId(null)}>Cancel</button>
                <button className="btn btn-warning" type="submit">✏️ Save Changes</button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  )
}


function EmployeesTab({ showMsg }) {
  const [employees, setEmployees] = useState([])
  const [hotels, setHotels] = useState([])
  const [loading, setLoading] = useState(true)
  const [showCreate, setShowCreate] = useState(false)
  const [editId, setEditId] = useState(null)
  const [editForm, setEditForm] = useState({})
  const [form, setForm] = useState({
    hotel_id: '', full_name: '', street: '', city: '', state: '',
    country: '', postal_code: '', ssn_sin: ''
  })

  function set(k, v) { setForm(f => ({ ...f, [k]: v })) }

  async function load() {
    setLoading(true)
    try {
      const [emps, htls] = await Promise.all([listEmployees(), listHotels()])
      setEmployees(emps)
      setHotels(htls)
    } catch (e) { showMsg('error', e.message) }
    finally { setLoading(false) }
  }

  useEffect(() => { load() }, [])

  async function handleCreate(e) {
    e.preventDefault()
    try {
      const res = await createEmployee({ ...form, hotel_id: Number(form.hotel_id) })
      showMsg('success', `✅ Employee created! ID: ${res.employee_id}`)
      setForm({ hotel_id: '', full_name: '', street: '', city: '', state: '', country: '', postal_code: '', ssn_sin: '' })
      setShowCreate(false)
      load()
    } catch (e) { showMsg('error', e.message) }
  }

  async function handleUpdate(e) {
    e.preventDefault()
    const data = Object.fromEntries(Object.entries(editForm).filter(([_, v]) => v !== ''))
    if (data.hotel_id) data.hotel_id = Number(data.hotel_id)
    try {
      await updateEmployee(editId, data)
      showMsg('success', `✅ Employee #${editId} updated.`)
      setEditId(null)
      load()
    } catch (e) { showMsg('error', e.message) }
  }

  async function handleDelete(id) {
    if (!window.confirm(`Delete employee #${id}?`)) return
    try {
      await deleteEmployee(id)
      showMsg('success', `✅ Employee #${id} deleted.`)
      load()
    } catch (e) { showMsg('error', e.message) }
  }

  function startEdit(emp) {
    setEditId(emp.employee_id)
    setEditForm({
      full_name: emp.full_name || '', street: emp.street || '', city: emp.city || '',
      state: emp.state || '', country: emp.country || '', postal_code: emp.postal_code || '',
      hotel_id: String(emp.hotel_id || ''), ssn_sin: emp.ssn_sin || ''
    })
  }

  if (loading) return <div className="loading-container"><div className="spinner" /><span>Loading…</span></div>

  return (
    <div className="animate-in">
      <div className="card">
        <div className="card-header">
          <h2>🧑‍💼 Employees <span className="badge">{employees.length}</span></h2>
          <button className="btn btn-success btn-sm" onClick={() => setShowCreate(!showCreate)}>
            {showCreate ? '▲ Hide Form' : '➕ Add Employee'}
          </button>
        </div>

        {showCreate && (
          <form onSubmit={handleCreate} style={{ marginBottom: '1.5rem', padding: '1rem', background: 'var(--border-light)', borderRadius: 'var(--radius-sm)' }}>
            <div className="form-grid">
              <div className="form-group"><label>Hotel *</label>
                <select required value={form.hotel_id} onChange={e => set('hotel_id', e.target.value)}>
                  <option value="">— Select hotel —</option>
                  {hotels.map(h => <option key={h.hotel_id} value={h.hotel_id}>#{h.hotel_id} — {h.hotel_name}</option>)}
                </select></div>
              <div className="form-group"><label>Full Name *</label>
                <input required value={form.full_name} onChange={e => set('full_name', e.target.value)} placeholder="Jane Smith" /></div>
              <div className="form-group"><label>SSN / SIN *</label>
                <input required value={form.ssn_sin} onChange={e => set('ssn_sin', e.target.value)} placeholder="987-654-321" /></div>
              <div className="form-group"><label>Street *</label>
                <input required value={form.street} onChange={e => set('street', e.target.value)} /></div>
              <div className="form-group"><label>City *</label>
                <input required value={form.city} onChange={e => set('city', e.target.value)} /></div>
              <div className="form-group"><label>State</label>
                <input value={form.state} onChange={e => set('state', e.target.value)} /></div>
              <div className="form-group"><label>Country *</label>
                <input required value={form.country} onChange={e => set('country', e.target.value)} /></div>
              <div className="form-group"><label>Postal Code</label>
                <input value={form.postal_code} onChange={e => set('postal_code', e.target.value)} /></div>
            </div>
            <button className="btn btn-success" type="submit">➕ Create</button>
          </form>
        )}

        {employees.length === 0 ? <p className="empty">No employees found.</p> : (
          <div className="table-wrap">
            <table>
              <thead>
                <tr><th>ID</th><th>Name</th><th>Hotel</th><th>City</th><th>Country</th><th>Actions</th></tr>
              </thead>
              <tbody>
                {employees.map(emp => (
                  <tr key={emp.employee_id}>
                    <td><strong>#{emp.employee_id}</strong></td>
                    <td>{emp.full_name}</td>
                    <td>{emp.hotel_name} <small>#{emp.hotel_id}</small></td>
                    <td>{emp.city}</td>
                    <td>{emp.country}</td>
                    <td>
                      <div className="flex-row" style={{ gap: '0.35rem' }}>
                        <button className="btn btn-warning btn-sm" onClick={() => startEdit(emp)}>✏️</button>
                        <button className="btn btn-danger btn-sm" onClick={() => handleDelete(emp.employee_id)}>🗑️</button>
                      </div>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </div>

      {editId && (
        <div className="modal-overlay" onClick={() => setEditId(null)}>
          <div className="modal" onClick={e => e.stopPropagation()}>
            <h2>✏️ Edit Employee #{editId}</h2>
            <form onSubmit={handleUpdate}>
              <div className="form-grid" style={{ gridTemplateColumns: '1fr 1fr' }}>
                <div className="form-group"><label>Full Name</label>
                  <input value={editForm.full_name} onChange={e => setEditForm(f => ({ ...f, full_name: e.target.value }))} /></div>
                <div className="form-group"><label>Hotel</label>
                  <select value={editForm.hotel_id} onChange={e => setEditForm(f => ({ ...f, hotel_id: e.target.value }))}>
                    <option value="">— No change —</option>
                    {hotels.map(h => <option key={h.hotel_id} value={h.hotel_id}>#{h.hotel_id} — {h.hotel_name}</option>)}
                  </select></div>
                <div className="form-group"><label>Street</label>
                  <input value={editForm.street} onChange={e => setEditForm(f => ({ ...f, street: e.target.value }))} /></div>
                <div className="form-group"><label>City</label>
                  <input value={editForm.city} onChange={e => setEditForm(f => ({ ...f, city: e.target.value }))} /></div>
                <div className="form-group"><label>State</label>
                  <input value={editForm.state} onChange={e => setEditForm(f => ({ ...f, state: e.target.value }))} /></div>
                <div className="form-group"><label>Country</label>
                  <input value={editForm.country} onChange={e => setEditForm(f => ({ ...f, country: e.target.value }))} /></div>
                <div className="form-group"><label>Postal Code</label>
                  <input value={editForm.postal_code} onChange={e => setEditForm(f => ({ ...f, postal_code: e.target.value }))} /></div>
              </div>
              <div className="modal-actions">
                <button className="btn btn-outline" type="button" onClick={() => setEditId(null)}>Cancel</button>
                <button className="btn btn-warning" type="submit">✏️ Save Changes</button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  )
}


function HotelsTab({ showMsg }) {
  const [hotels, setHotels] = useState([])
  const [chains, setChains] = useState([])
  const [loading, setLoading] = useState(true)
  const [showCreate, setShowCreate] = useState(false)
  const [editId, setEditId] = useState(null)
  const [editForm, setEditForm] = useState({})
  const [form, setForm] = useState({
    chain_id: '', hotel_name: '', star_rating: '3',
    street: '', city: '', state: '', country: '', postal_code: '', area: ''
  })

  function set(k, v) { setForm(f => ({ ...f, [k]: v })) }

  async function load() {
    setLoading(true)
    try {
      const [htls, chs] = await Promise.all([listHotels(), listChains()])
      setHotels(htls)
      setChains(chs)
    } catch (e) { showMsg('error', e.message) }
    finally { setLoading(false) }
  }

  useEffect(() => { load() }, [])

  async function handleCreate(e) {
    e.preventDefault()
    try {
      const res = await createHotel({ ...form, chain_id: Number(form.chain_id), star_rating: Number(form.star_rating) })
      showMsg('success', `✅ Hotel created! ID: ${res.hotel_id}`)
      setForm({ chain_id: '', hotel_name: '', star_rating: '3', street: '', city: '', state: '', country: '', postal_code: '', area: '' })
      setShowCreate(false)
      load()
    } catch (e) { showMsg('error', e.message) }
  }

  async function handleUpdate(e) {
    e.preventDefault()
    const data = Object.fromEntries(Object.entries(editForm).filter(([_, v]) => v !== ''))
    if (data.star_rating) data.star_rating = Number(data.star_rating)
    if (data.chain_id) data.chain_id = Number(data.chain_id)
    try {
      await updateHotel(editId, data)
      showMsg('success', `✅ Hotel #${editId} updated.`)
      setEditId(null)
      load()
    } catch (e) { showMsg('error', e.message) }
  }

  async function handleDelete(id) {
    if (!window.confirm(`Delete hotel #${id}? All its rooms will also be deleted.`)) return
    try {
      await deleteHotel(id)
      showMsg('success', `✅ Hotel #${id} deleted.`)
      load()
    } catch (e) { showMsg('error', e.message) }
  }

  function startEdit(h) {
    setEditId(h.hotel_id)
    setEditForm({
      chain_id: String(h.chain_id || ''), hotel_name: h.hotel_name || '', star_rating: String(h.star_rating || ''),
      street: h.street || '', city: h.city || '', state: h.state || '',
      country: h.country || '', postal_code: h.postal_code || '', area: h.area || ''
    })
  }

  if (loading) return <div className="loading-container"><div className="spinner" /><span>Loading…</span></div>

  return (
    <div className="animate-in">
      <div className="card">
        <div className="card-header">
          <h2>🏨 Hotels <span className="badge">{hotels.length}</span></h2>
          <button className="btn btn-success btn-sm" onClick={() => setShowCreate(!showCreate)}>
            {showCreate ? '▲ Hide Form' : '➕ Add Hotel'}
          </button>
        </div>

        {showCreate && (
          <form onSubmit={handleCreate} style={{ marginBottom: '1.5rem', padding: '1rem', background: 'var(--border-light)', borderRadius: 'var(--radius-sm)' }}>
            <div className="form-grid">
              <div className="form-group"><label>Hotel Chain *</label>
                <select required value={form.chain_id} onChange={e => set('chain_id', e.target.value)}>
                  <option value="">— Select chain —</option>
                  {chains.map(c => <option key={c.chain_id} value={c.chain_id}>#{c.chain_id} — {c.chain_name}</option>)}
                </select></div>
              <div className="form-group"><label>Hotel Name *</label>
                <input required value={form.hotel_name} onChange={e => set('hotel_name', e.target.value)} placeholder="Grand Hotel" /></div>
              <div className="form-group"><label>Star Rating *</label>
                <select value={form.star_rating} onChange={e => set('star_rating', e.target.value)}>
                  {[1,2,3,4,5].map(s => <option key={s} value={s}>{'⭐'.repeat(s)}</option>)}
                </select></div>
              <div className="form-group"><label>Area *</label>
                <input required value={form.area} onChange={e => set('area', e.target.value)} placeholder="Miami Beach" /></div>
              <div className="form-group"><label>Street *</label>
                <input required value={form.street} onChange={e => set('street', e.target.value)} /></div>
              <div className="form-group"><label>City *</label>
                <input required value={form.city} onChange={e => set('city', e.target.value)} /></div>
              <div className="form-group"><label>State</label>
                <input value={form.state} onChange={e => set('state', e.target.value)} /></div>
              <div className="form-group"><label>Country *</label>
                <input required value={form.country} onChange={e => set('country', e.target.value)} /></div>
              <div className="form-group"><label>Postal Code</label>
                <input value={form.postal_code} onChange={e => set('postal_code', e.target.value)} /></div>
            </div>
            <button className="btn btn-success" type="submit">➕ Create</button>
          </form>
        )}

        {hotels.length === 0 ? <p className="empty">No hotels found.</p> : (
          <div className="table-wrap">
            <table>
              <thead>
                <tr><th>ID</th><th>Name</th><th>Chain</th><th>Stars</th><th>Area</th><th>City</th><th>Actions</th></tr>
              </thead>
              <tbody>
                {hotels.map(h => (
                  <tr key={h.hotel_id}>
                    <td><strong>#{h.hotel_id}</strong></td>
                    <td>{h.hotel_name}</td>
                    <td>{h.chain_name}</td>
                    <td>{'⭐'.repeat(h.star_rating)}</td>
                    <td>📍 {h.area}</td>
                    <td>{h.city}, {h.country}</td>
                    <td>
                      <div className="flex-row" style={{ gap: '0.35rem' }}>
                        <button className="btn btn-warning btn-sm" onClick={() => startEdit(h)}>✏️</button>
                        <button className="btn btn-danger btn-sm" onClick={() => handleDelete(h.hotel_id)}>🗑️</button>
                      </div>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </div>

      {editId && (
        <div className="modal-overlay" onClick={() => setEditId(null)}>
          <div className="modal" onClick={e => e.stopPropagation()}>
            <h2>✏️ Edit Hotel #{editId}</h2>
            <form onSubmit={handleUpdate}>
               <div className="form-grid" style={{ gridTemplateColumns: '1fr 1fr' }}>
                <div className="form-group"><label>Hotel Name</label>
                  <input value={editForm.hotel_name} onChange={e => setEditForm(f => ({ ...f, hotel_name: e.target.value }))} /></div>
                <div className="form-group"><label>Hotel Chain</label>
                  <select value={editForm.chain_id} onChange={e => setEditForm(f => ({ ...f, chain_id: e.target.value }))}>
                    <option value="">— No change —</option>
                    {chains.map(c => <option key={c.chain_id} value={c.chain_id}>#{c.chain_id} — {c.chain_name}</option>)}
                  </select></div>
                <div className="form-group"><label>Star Rating</label>
                  <select value={editForm.star_rating} onChange={e => setEditForm(f => ({ ...f, star_rating: e.target.value }))}>
                    {[1,2,3,4,5].map(s => <option key={s} value={s}>{'⭐'.repeat(s)}</option>)}
                  </select></div>
                <div className="form-group"><label>Area</label>
                  <input value={editForm.area} onChange={e => setEditForm(f => ({ ...f, area: e.target.value }))} /></div>
                <div className="form-group"><label>Street</label>
                  <input value={editForm.street} onChange={e => setEditForm(f => ({ ...f, street: e.target.value }))} /></div>
                <div className="form-group"><label>City</label>
                  <input value={editForm.city} onChange={e => setEditForm(f => ({ ...f, city: e.target.value }))} /></div>
                <div className="form-group"><label>State</label>
                  <input value={editForm.state} onChange={e => setEditForm(f => ({ ...f, state: e.target.value }))} /></div>
                <div className="form-group"><label>Country</label>
                  <input value={editForm.country} onChange={e => setEditForm(f => ({ ...f, country: e.target.value }))} /></div>
                <div className="form-group"><label>Postal Code</label>
                  <input value={editForm.postal_code} onChange={e => setEditForm(f => ({ ...f, postal_code: e.target.value }))} /></div>
              </div>
              <div className="modal-actions">
                <button className="btn btn-outline" type="button" onClick={() => setEditId(null)}>Cancel</button>
                <button className="btn btn-warning" type="submit">✏️ Save Changes</button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  )
}


function RoomsTab({ showMsg }) {
  const [rooms, setRooms] = useState([])
  const [hotels, setHotels] = useState([])
  const [loading, setLoading] = useState(true)
  const [showCreate, setShowCreate] = useState(false)
  const [editId, setEditId] = useState(null)
  const [editForm, setEditForm] = useState({})
  const [form, setForm] = useState({
    hotel_id: '', room_number: '', price_per_night: '',
    capacity: 'single', view_type: 'none', extendable: false, problem_notes: ''
  })

  function set(k, v) { setForm(f => ({ ...f, [k]: v })) }

  async function load() {
    setLoading(true)
    try {
      const [rms, htls] = await Promise.all([listRooms(), listHotels()])
      setRooms(rms)
      setHotels(htls)
    } catch (e) { showMsg('error', e.message) }
    finally { setLoading(false) }
  }

  useEffect(() => { load() }, [])

  async function handleCreate(e) {
    e.preventDefault()
    try {
      const res = await createRoom({
        ...form,
        hotel_id: Number(form.hotel_id),
        price_per_night: Number(form.price_per_night),
        extendable: form.extendable === true || form.extendable === 'true',
        problem_notes: form.problem_notes || null,
      })
      showMsg('success', `✅ Room created! ID: ${res.room_id}`)
      setForm({ hotel_id: '', room_number: '', price_per_night: '', capacity: 'single', view_type: 'none', extendable: false, problem_notes: '' })
      setShowCreate(false)
      load()
    } catch (e) { showMsg('error', e.message) }
  }

  async function handleUpdate(e) {
    e.preventDefault()
    const data = {}
    if (editForm.room_number) data.room_number = editForm.room_number
    if (editForm.price_per_night) data.price_per_night = Number(editForm.price_per_night)
    if (editForm.capacity) data.capacity = editForm.capacity
    if (editForm.view_type) data.view_type = editForm.view_type
    if (editForm.extendable !== undefined && editForm.extendable !== '') data.extendable = editForm.extendable === true || editForm.extendable === 'true'
    if (editForm.problem_notes !== undefined) data.problem_notes = editForm.problem_notes || null
    try {
      await updateRoom(editId, data)
      showMsg('success', `✅ Room #${editId} updated.`)
      setEditId(null)
      load()
    } catch (e) { showMsg('error', e.message) }
  }

  async function handleDelete(id) {
    if (!window.confirm(`Delete room #${id}?`)) return
    try {
      await deleteRoom(id)
      showMsg('success', `✅ Room #${id} deleted.`)
      load()
    } catch (e) { showMsg('error', e.message) }
  }

  function startEdit(r) {
    setEditId(r.room_id)
    setEditForm({
      room_number: r.room_number || '', price_per_night: String(r.price_per_night || ''),
      capacity: r.capacity || 'single', view_type: r.view_type || 'none',
      extendable: r.extendable || false, problem_notes: r.problem_notes || ''
    })
  }

  if (loading) return <div className="loading-container"><div className="spinner" /><span>Loading…</span></div>

  return (
    <div className="animate-in">
      <div className="card">
        <div className="card-header">
          <h2>🛏 Rooms <span className="badge">{rooms.length}</span></h2>
          <button className="btn btn-success btn-sm" onClick={() => setShowCreate(!showCreate)}>
            {showCreate ? '▲ Hide Form' : '➕ Add Room'}
          </button>
        </div>

        {showCreate && (
          <form onSubmit={handleCreate} style={{ marginBottom: '1.5rem', padding: '1rem', background: 'var(--border-light)', borderRadius: 'var(--radius-sm)' }}>
            <div className="form-grid">
              <div className="form-group"><label>Hotel *</label>
                <select required value={form.hotel_id} onChange={e => set('hotel_id', e.target.value)}>
                  <option value="">— Select hotel —</option>
                  {hotels.map(h => <option key={h.hotel_id} value={h.hotel_id}>#{h.hotel_id} — {h.hotel_name}</option>)}
                </select></div>
              <div className="form-group"><label>Room Number *</label>
                <input required value={form.room_number} onChange={e => set('room_number', e.target.value)} placeholder="e.g. 101" /></div>
              <div className="form-group"><label>Price / Night ($) *</label>
                <input type="number" required min="0" step="0.01" value={form.price_per_night}
                  onChange={e => set('price_per_night', e.target.value)} placeholder="120.00" /></div>
              <div className="form-group"><label>Capacity *</label>
                <select value={form.capacity} onChange={e => set('capacity', e.target.value)}>
                  {['single','double','triple','quad','suite'].map(c =>
                    <option key={c} value={c}>{c.charAt(0).toUpperCase() + c.slice(1)}</option>)}
                </select></div>
              <div className="form-group"><label>View Type</label>
                <select value={form.view_type} onChange={e => set('view_type', e.target.value)}>
                  <option value="none">None</option>
                  <option value="sea">🌊 Sea</option>
                  <option value="mountain">⛰ Mountain</option>
                </select></div>
              <div className="form-group"><label>Extendable?</label>
                <select value={form.extendable} onChange={e => set('extendable', e.target.value === 'true')}>
                  <option value={false}>No</option>
                  <option value={true}>Yes</option>
                </select></div>
              <div className="form-group"><label>Problem Notes</label>
                <input value={form.problem_notes} onChange={e => set('problem_notes', e.target.value)} placeholder="Optional" /></div>
            </div>
            <button className="btn btn-success" type="submit">➕ Create</button>
          </form>
        )}

        {rooms.length === 0 ? <p className="empty">No rooms found.</p> : (
          <div className="table-wrap">
            <table>
              <thead>
                <tr><th>ID</th><th>Hotel</th><th>Room #</th><th>Price</th><th>Capacity</th><th>View</th><th>Ext.</th><th>Actions</th></tr>
              </thead>
              <tbody>
                {rooms.map(r => (
                  <tr key={r.room_id}>
                    <td><strong>#{r.room_id}</strong></td>
                    <td>{r.hotel_name}</td>
                    <td>{r.room_number}</td>
                    <td><strong>${Number(r.price_per_night).toFixed(2)}</strong></td>
                    <td>{r.capacity}</td>
                    <td>{r.view_type === 'sea' ? '🌊' : r.view_type === 'mountain' ? '⛰' : '—'}</td>
                    <td>{r.extendable ? '✅' : '—'}</td>
                    <td>
                      <div className="flex-row" style={{ gap: '0.35rem' }}>
                        <button className="btn btn-warning btn-sm" onClick={() => startEdit(r)}>✏️</button>
                        <button className="btn btn-danger btn-sm" onClick={() => handleDelete(r.room_id)}>🗑️</button>
                      </div>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </div>

      {editId && (
        <div className="modal-overlay" onClick={() => setEditId(null)}>
          <div className="modal" onClick={e => e.stopPropagation()}>
            <h2>✏️ Edit Room #{editId}</h2>
            <form onSubmit={handleUpdate}>
              <div className="form-grid" style={{ gridTemplateColumns: '1fr 1fr' }}>
                <div className="form-group"><label>Room Number</label>
                  <input value={editForm.room_number} onChange={e => setEditForm(f => ({ ...f, room_number: e.target.value }))} /></div>
                <div className="form-group"><label>Price / Night ($)</label>
                  <input type="number" min="0" step="0.01" value={editForm.price_per_night}
                    onChange={e => setEditForm(f => ({ ...f, price_per_night: e.target.value }))} /></div>
                <div className="form-group"><label>Capacity</label>
                  <select value={editForm.capacity} onChange={e => setEditForm(f => ({ ...f, capacity: e.target.value }))}>
                    {['single','double','triple','quad','suite'].map(c =>
                      <option key={c} value={c}>{c.charAt(0).toUpperCase() + c.slice(1)}</option>)}
                  </select></div>
                <div className="form-group"><label>View Type</label>
                  <select value={editForm.view_type} onChange={e => setEditForm(f => ({ ...f, view_type: e.target.value }))}>
                    <option value="none">None</option>
                    <option value="sea">🌊 Sea</option>
                    <option value="mountain">⛰ Mountain</option>
                  </select></div>
                <div className="form-group"><label>Extendable?</label>
                  <select value={editForm.extendable} onChange={e => setEditForm(f => ({ ...f, extendable: e.target.value === 'true' }))}>
                    <option value={false}>No</option>
                    <option value={true}>Yes</option>
                  </select></div>
                <div className="form-group"><label>Problem Notes</label>
                  <input value={editForm.problem_notes} onChange={e => setEditForm(f => ({ ...f, problem_notes: e.target.value }))} /></div>
              </div>
              <div className="modal-actions">
                <button className="btn btn-outline" type="button" onClick={() => setEditId(null)}>Cancel</button>
                <button className="btn btn-warning" type="submit">✏️ Save Changes</button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  )
}
