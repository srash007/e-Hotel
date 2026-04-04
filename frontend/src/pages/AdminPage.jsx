import { useState } from 'react'
import {
  createCustomer, updateCustomer, deleteCustomer,
  createEmployee, deleteEmployee,
  createHotel, deleteHotel,
  createRoom, deleteRoom,
} from '../api'

const TABS = ['Customers', 'Employees', 'Hotels', 'Rooms']

export default function AdminPage() {
  const [tab, setTab] = useState(0)
  const [msg, setMsg] = useState(null)

  function showMsg(type, text) { setMsg({ type, text }); setTimeout(() => setMsg(null), 5000) }

  return (
    <div className="page">
      <h1>⚙️ Admin Panel — Manage Data</h1>
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

// ── Customers ─────────────────────────────────────────────────
function CustomersTab({ showMsg }) {
  const [form, setForm] = useState({
    full_name: '', street: '', city: '', state: '', country: '', postal_code: '',
    id_type: 'SIN', id_value: ''
  })
  const [updateForm, setUpdateForm] = useState({ customer_id: '', full_name: '', city: '', country: '' })
  const [deleteId, setDeleteId] = useState('')

  function set(k, v) { setForm(f => ({ ...f, [k]: v })) }

  async function handleCreate(e) {
    e.preventDefault()
    try {
      const res = await createCustomer(form)
      showMsg('success', `✅ Customer created! ID: ${res.customer_id}`)
      setForm({ full_name: '', street: '', city: '', state: '', country: '', postal_code: '', id_type: 'SIN', id_value: '' })
    } catch (e) { showMsg('error', e.message) }
  }

  async function handleUpdate(e) {
    e.preventDefault()
    const { customer_id, ...rest } = updateForm
    const data = Object.fromEntries(Object.entries(rest).filter(([_, v]) => v !== ''))
    try {
      await updateCustomer(Number(customer_id), data)
      showMsg('success', `✅ Customer #${customer_id} updated.`)
    } catch (e) { showMsg('error', e.message) }
  }

  async function handleDelete(e) {
    e.preventDefault()
    if (!window.confirm(`Delete customer #${deleteId}?`)) return
    try {
      await deleteCustomer(Number(deleteId))
      showMsg('success', `✅ Customer #${deleteId} deleted.`)
      setDeleteId('')
    } catch (e) { showMsg('error', e.message) }
  }

  return (
    <>
      <div className="card">
        <h2>➕ Add New Customer</h2>
        <form onSubmit={handleCreate}>
          <div className="form-grid">
            <div className="form-group"><label>Full Name *</label>
              <input required value={form.full_name} onChange={e => set('full_name', e.target.value)} /></div>
            <div className="form-group"><label>Street *</label>
              <input required value={form.street} onChange={e => set('street', e.target.value)} /></div>
            <div className="form-group"><label>City *</label>
              <input required value={form.city} onChange={e => set('city', e.target.value)} /></div>
            <div className="form-group"><label>State / Province</label>
              <input value={form.state} onChange={e => set('state', e.target.value)} /></div>
            <div className="form-group"><label>Country *</label>
              <input required value={form.country} onChange={e => set('country', e.target.value)} /></div>
            <div className="form-group"><label>Postal Code</label>
              <input value={form.postal_code} onChange={e => set('postal_code', e.target.value)} /></div>
            <div className="form-group"><label>ID Type *</label>
              <select value={form.id_type} onChange={e => set('id_type', e.target.value)}>
                <option value="SSN">SSN</option>
                <option value="SIN">SIN</option>
                <option value="DRIVER_LICENCE">Driver's Licence</option>
                <option value="PASSPORT">Passport</option>
              </select>
            </div>
            <div className="form-group"><label>ID Value *</label>
              <input required value={form.id_value} onChange={e => set('id_value', e.target.value)} placeholder="e.g. 123-45-6789" /></div>
          </div>
          <button className="btn btn-success" type="submit">➕ Create Customer</button>
        </form>
      </div>

      <div className="card">
        <h2>✏️ Update Customer</h2>
        <form onSubmit={handleUpdate}>
          <div className="form-grid">
            <div className="form-group"><label>Customer ID *</label>
              <input type="number" required value={updateForm.customer_id}
                onChange={e => setUpdateForm(f => ({ ...f, customer_id: e.target.value }))} placeholder="e.g. 5" /></div>
            <div className="form-group"><label>New Full Name</label>
              <input value={updateForm.full_name}
                onChange={e => setUpdateForm(f => ({ ...f, full_name: e.target.value }))} /></div>
            <div className="form-group"><label>New City</label>
              <input value={updateForm.city}
                onChange={e => setUpdateForm(f => ({ ...f, city: e.target.value }))} /></div>
            <div className="form-group"><label>New Country</label>
              <input value={updateForm.country}
                onChange={e => setUpdateForm(f => ({ ...f, country: e.target.value }))} /></div>
          </div>
          <button className="btn btn-warning" type="submit">✏️ Update</button>
        </form>
      </div>

      <div className="card">
        <h2>🗑️ Delete Customer</h2>
        <form onSubmit={handleDelete}>
          <div className="flex-row">
            <div className="form-group">
              <label>Customer ID *</label>
              <input type="number" required value={deleteId} onChange={e => setDeleteId(e.target.value)} placeholder="e.g. 5" />
            </div>
            <button className="btn btn-danger mt-2" type="submit" style={{ marginTop: '1.4rem' }}>🗑️ Delete</button>
          </div>
        </form>
      </div>
    </>
  )
}

// ── Employees ─────────────────────────────────────────────────
function EmployeesTab({ showMsg }) {
  const [form, setForm] = useState({
    hotel_id: '', full_name: '', street: '', city: '', state: '',
    country: '', postal_code: '', ssn_sin: ''
  })
  const [deleteId, setDeleteId] = useState('')

  function set(k, v) { setForm(f => ({ ...f, [k]: v })) }

  async function handleCreate(e) {
    e.preventDefault()
    try {
      const res = await createEmployee({ ...form, hotel_id: Number(form.hotel_id) })
      showMsg('success', `✅ Employee created! ID: ${res.employee_id}`)
      setForm({ hotel_id: '', full_name: '', street: '', city: '', state: '', country: '', postal_code: '', ssn_sin: '' })
    } catch (e) { showMsg('error', e.message) }
  }

  async function handleDelete(e) {
    e.preventDefault()
    if (!window.confirm(`Delete employee #${deleteId}?`)) return
    try {
      await deleteEmployee(Number(deleteId))
      showMsg('success', `✅ Employee #${deleteId} deleted.`)
      setDeleteId('')
    } catch (e) { showMsg('error', e.message) }
  }

  return (
    <>
      <div className="card">
        <h2>➕ Add New Employee</h2>
        <form onSubmit={handleCreate}>
          <div className="form-grid">
            <div className="form-group"><label>Hotel ID *</label>
              <input type="number" required value={form.hotel_id} onChange={e => set('hotel_id', e.target.value)} /></div>
            <div className="form-group"><label>Full Name *</label>
              <input required value={form.full_name} onChange={e => set('full_name', e.target.value)} /></div>
            <div className="form-group"><label>SSN / SIN *</label>
              <input required value={form.ssn_sin} onChange={e => set('ssn_sin', e.target.value)} placeholder="e.g. 987-65-4321" /></div>
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
          <button className="btn btn-success" type="submit">➕ Create Employee</button>
        </form>
      </div>
      <div className="card">
        <h2>🗑️ Delete Employee</h2>
        <form onSubmit={handleDelete}>
          <div className="flex-row">
            <div className="form-group">
              <label>Employee ID *</label>
              <input type="number" required value={deleteId} onChange={e => setDeleteId(e.target.value)} placeholder="e.g. 8" />
            </div>
            <button className="btn btn-danger" type="submit" style={{ marginTop: '1.4rem' }}>🗑️ Delete</button>
          </div>
        </form>
      </div>
    </>
  )
}

// ── Hotels ────────────────────────────────────────────────────
function HotelsTab({ showMsg }) {
  const [form, setForm] = useState({
    chain_id: '', hotel_name: '', star_rating: '3',
    street: '', city: '', state: '', country: '', postal_code: '', area: ''
  })
  const [deleteId, setDeleteId] = useState('')

  function set(k, v) { setForm(f => ({ ...f, [k]: v })) }

  async function handleCreate(e) {
    e.preventDefault()
    try {
      const res = await createHotel({ ...form, chain_id: Number(form.chain_id), star_rating: Number(form.star_rating) })
      showMsg('success', `✅ Hotel created! ID: ${res.hotel_id}`)
      setForm({ chain_id: '', hotel_name: '', star_rating: '3', street: '', city: '', state: '', country: '', postal_code: '', area: '' })
    } catch (e) { showMsg('error', e.message) }
  }

  async function handleDelete(e) {
    e.preventDefault()
    if (!window.confirm(`Delete hotel #${deleteId}? All its rooms will also be deleted.`)) return
    try {
      await deleteHotel(Number(deleteId))
      showMsg('success', `✅ Hotel #${deleteId} deleted.`)
      setDeleteId('')
    } catch (e) { showMsg('error', e.message) }
  }

  return (
    <>
      <div className="card">
        <h2>➕ Add New Hotel</h2>
        <form onSubmit={handleCreate}>
          <div className="form-grid">
            <div className="form-group"><label>Chain ID *</label>
              <input type="number" required value={form.chain_id} onChange={e => set('chain_id', e.target.value)} /></div>
            <div className="form-group"><label>Hotel Name *</label>
              <input required value={form.hotel_name} onChange={e => set('hotel_name', e.target.value)} /></div>
            <div className="form-group"><label>Star Rating *</label>
              <select value={form.star_rating} onChange={e => set('star_rating', e.target.value)}>
                {[1,2,3,4,5].map(s => <option key={s} value={s}>{'⭐'.repeat(s)}</option>)}
              </select>
            </div>
            <div className="form-group"><label>Area *</label>
              <input required value={form.area} onChange={e => set('area', e.target.value)} placeholder="e.g. Miami Beach" /></div>
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
          <button className="btn btn-success" type="submit">➕ Create Hotel</button>
        </form>
      </div>
      <div className="card">
        <h2>🗑️ Delete Hotel</h2>
        <form onSubmit={handleDelete}>
          <div className="flex-row">
            <div className="form-group">
              <label>Hotel ID *</label>
              <input type="number" required value={deleteId} onChange={e => setDeleteId(e.target.value)} placeholder="e.g. 3" />
            </div>
            <button className="btn btn-danger" type="submit" style={{ marginTop: '1.4rem' }}>🗑️ Delete</button>
          </div>
        </form>
      </div>
    </>
  )
}

// ── Rooms ─────────────────────────────────────────────────────
function RoomsTab({ showMsg }) {
  const [form, setForm] = useState({
    hotel_id: '', room_number: '', price_per_night: '',
    capacity: 'single', view_type: 'none', extendable: false, problem_notes: ''
  })
  const [deleteId, setDeleteId] = useState('')

  function set(k, v) { setForm(f => ({ ...f, [k]: v })) }

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
    } catch (e) { showMsg('error', e.message) }
  }

  async function handleDelete(e) {
    e.preventDefault()
    if (!window.confirm(`Delete room #${deleteId}?`)) return
    try {
      await deleteRoom(Number(deleteId))
      showMsg('success', `✅ Room #${deleteId} deleted.`)
      setDeleteId('')
    } catch (e) { showMsg('error', e.message) }
  }

  return (
    <>
      <div className="card">
        <h2>➕ Add New Room</h2>
        <form onSubmit={handleCreate}>
          <div className="form-grid">
            <div className="form-group"><label>Hotel ID *</label>
              <input type="number" required value={form.hotel_id} onChange={e => set('hotel_id', e.target.value)} /></div>
            <div className="form-group"><label>Room Number *</label>
              <input required value={form.room_number} onChange={e => set('room_number', e.target.value)} placeholder="e.g. 101" /></div>
            <div className="form-group"><label>Price / Night ($) *</label>
              <input type="number" required min="0" step="0.01" value={form.price_per_night}
                onChange={e => set('price_per_night', e.target.value)} placeholder="e.g. 120.00" /></div>
            <div className="form-group"><label>Capacity *</label>
              <select value={form.capacity} onChange={e => set('capacity', e.target.value)}>
                {['single','double','triple','quad','suite'].map(c =>
                  <option key={c} value={c}>{c.charAt(0).toUpperCase() + c.slice(1)}</option>)}
              </select>
            </div>
            <div className="form-group"><label>View</label>
              <select value={form.view_type} onChange={e => set('view_type', e.target.value)}>
                <option value="none">None</option>
                <option value="sea">Sea</option>
                <option value="mountain">Mountain</option>
              </select>
            </div>
            <div className="form-group"><label>Extendable?</label>
              <select value={form.extendable} onChange={e => set('extendable', e.target.value === 'true')}>
                <option value={false}>No</option>
                <option value={true}>Yes</option>
              </select>
            </div>
            <div className="form-group"><label>Problem Notes</label>
              <input value={form.problem_notes} onChange={e => set('problem_notes', e.target.value)} placeholder="Optional" /></div>
          </div>
          <button className="btn btn-success" type="submit">➕ Create Room</button>
        </form>
      </div>
      <div className="card">
        <h2>🗑️ Delete Room</h2>
        <form onSubmit={handleDelete}>
          <div className="flex-row">
            <div className="form-group">
              <label>Room ID *</label>
              <input type="number" required value={deleteId} onChange={e => setDeleteId(e.target.value)} placeholder="e.g. 42" />
            </div>
            <button className="btn btn-danger" type="submit" style={{ marginTop: '1.4rem' }}>🗑️ Delete</button>
          </div>
        </form>
      </div>
    </>
  )
}
