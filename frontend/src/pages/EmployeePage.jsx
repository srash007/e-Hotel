import { useState, useEffect } from 'react'
import {
  getActiveBookings, cancelBooking,
  checkIn, walkIn,
  getActiveRentings,
  addPayment, listPayments,
  listCustomers, listEmployees, listRooms
} from '../api'

const TABS = ['📋 Bookings', '✅ Check-In', '🚶 Walk-In', '🏨 Rentings', '💳 Payments']

export default function EmployeePage() {
  const [tab, setTab] = useState(0)
  const [msg, setMsg] = useState(null)

  function showMsg(type, text) { setMsg({ type, text }); setTimeout(() => setMsg(null), 5000) }

  return (
    <div className="page">
      <h1>👷 Employee Dashboard</h1>
      <p className="page-subtitle">Manage bookings, check-ins, walk-in rentals, and payments.</p>
      {msg && <div className={`alert alert-${msg.type}`}>{msg.text}</div>}

      <div className="tabs">
        {TABS.map((t, i) => (
          <button key={t} className={`tab${tab === i ? ' active' : ''}`} onClick={() => setTab(i)}>{t}</button>
        ))}
      </div>

      {tab === 0 && <ActiveBookings showMsg={showMsg} />}
      {tab === 1 && <CheckIn showMsg={showMsg} />}
      {tab === 2 && <WalkIn showMsg={showMsg} />}
      {tab === 3 && <ActiveRentings />}
      {tab === 4 && <Payments showMsg={showMsg} />}
    </div>
  )
}

function ActiveBookings({ showMsg }) {
  const [bookings, setBookings] = useState([])
  const [loading, setLoading] = useState(true)

  async function load() {
    setLoading(true)
    try { setBookings(await getActiveBookings()) }
    catch (e) { showMsg('error', e.message) }
    finally { setLoading(false) }
  }

  useEffect(() => { load() }, [])

  async function handleCancel(id) {
    if (!window.confirm(`Cancel booking #${id}?`)) return
    try {
      await cancelBooking(id)
      showMsg('success', `Booking #${id} cancelled.`)
      load()
    } catch (e) { showMsg('error', e.message) }
  }

  if (loading) return <div className="loading-container"><div className="spinner" /><span>Loading bookings…</span></div>

  return (
    <div className="card animate-in">
      <h2>Active Bookings <span className="badge">{bookings.length}</span></h2>
      {bookings.length === 0
        ? <p className="empty">No active bookings at the moment.</p>
        : (
          <div className="table-wrap">
            <table>
              <thead>
                <tr>
                  <th>ID</th><th>Customer</th><th>Hotel</th><th>Room</th>
                  <th>Check-in</th><th>Check-out</th><th>Status</th><th>Action</th>
                </tr>
              </thead>
              <tbody>
                {bookings.map(b => (
                  <tr key={b.booking_id}>
                    <td><strong>#{b.booking_id}</strong></td>
                    <td>{b.customer_name} <small>ID: {b.customer_id}</small></td>
                    <td>{b.hotel_name}</td>
                    <td>{b.room_number}</td>
                    <td>{b.start_date}</td>
                    <td>{b.end_date}</td>
                    <td><span className="amenity-tag">{b.status}</span></td>
                    <td>
                      <button className="btn btn-danger btn-sm" onClick={() => handleCancel(b.booking_id)}>
                        Cancel
                      </button>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
    </div>
  )
}

function CheckIn({ showMsg }) {
  const [bookings, setBookings] = useState([])
  const [employees, setEmployees] = useState([])
  const [selectedBooking, setSelectedBooking] = useState('')
  const [selectedEmployee, setSelectedEmployee] = useState('')

  useEffect(() => {
    getActiveBookings().then(setBookings).catch(console.error)
    listEmployees().then(setEmployees).catch(console.error)
  }, [])

  async function handleSubmit(e) {
    e.preventDefault()
    try {
      const res = await checkIn(Number(selectedBooking), Number(selectedEmployee))
      showMsg('success', `✅ Check-in complete! Renting #${res.renting_id} created.`)
      setSelectedBooking('')
      setSelectedEmployee('')
      // Refresh bookings
      getActiveBookings().then(setBookings).catch(console.error)
    } catch (e) { showMsg('error', e.message) }
  }

  return (
    <div className="card animate-in">
      <h2>✅ Check-In from Booking</h2>
      <p className="description">Transform an existing booking into a renting when the customer arrives.</p>
      <form onSubmit={handleSubmit}>
        <div className="form-grid">
          <div className="form-group">
            <label>Select Booking *</label>
            <select required value={selectedBooking} onChange={e => setSelectedBooking(e.target.value)}>
              <option value="">— Choose a booking —</option>
              {bookings.map(b => (
                <option key={b.booking_id} value={b.booking_id}>
                  #{b.booking_id} — {b.customer_name} → {b.hotel_name} Rm {b.room_number} ({b.start_date} to {b.end_date})
                </option>
              ))}
            </select>
          </div>
          <div className="form-group">
            <label>Select Employee *</label>
            <select required value={selectedEmployee} onChange={e => setSelectedEmployee(e.target.value)}>
              <option value="">— Choose an employee —</option>
              {employees.map(emp => (
                <option key={emp.employee_id} value={emp.employee_id}>
                  #{emp.employee_id} — {emp.full_name} ({emp.hotel_name})
                </option>
              ))}
            </select>
          </div>
        </div>
        <button className="btn btn-success" type="submit">✅ Check-In Customer</button>
      </form>
    </div>
  )
}

function WalkIn({ showMsg }) {
  const [customers, setCustomers] = useState([])
  const [employees, setEmployees] = useState([])
  const [rooms, setRooms] = useState([])
  const [form, setForm] = useState({
    customer_id: '', room_id: '', start_date: '', end_date: '', employee_id: ''
  })

  useEffect(() => {
    listCustomers().then(setCustomers).catch(console.error)
    listEmployees().then(setEmployees).catch(console.error)
    listRooms().then(setRooms).catch(console.error)
  }, [])

  function set(k, v) { setForm(f => ({ ...f, [k]: v })) }

  async function handleSubmit(e) {
    e.preventDefault()
    try {
      const payload = {
        customer_id: Number(form.customer_id),
        room_id: Number(form.room_id),
        start_date: form.start_date,
        end_date: form.end_date,
        employee_id: Number(form.employee_id),
      }
      const res = await walkIn(payload)
      showMsg('success', `✅ Walk-in renting #${res.renting_id} created!`)
      setForm({ customer_id: '', room_id: '', start_date: '', end_date: '', employee_id: '' })
    } catch (e) { showMsg('error', e.message) }
  }

  return (
    <div className="card animate-in">
      <h2>🚶 Walk-In Renting</h2>
      <p className="description">Create a direct renting for a customer who shows up without a booking.</p>
      <form onSubmit={handleSubmit}>
        <div className="form-grid">
          <div className="form-group">
            <label>Customer *</label>
            <select required value={form.customer_id} onChange={e => set('customer_id', e.target.value)}>
              <option value="">— Choose a customer —</option>
              {customers.map(c => (
                <option key={c.customer_id} value={c.customer_id}>
                  #{c.customer_id} — {c.full_name}
                </option>
              ))}
            </select>
          </div>
          <div className="form-group">
            <label>Room *</label>
            <select required value={form.room_id} onChange={e => set('room_id', e.target.value)}>
              <option value="">— Choose a room —</option>
              {rooms.map(r => (
                <option key={r.room_id} value={r.room_id}>
                  #{r.room_id} — {r.hotel_name} Rm {r.room_number} (${Number(r.price_per_night).toFixed(0)}/n)
                </option>
              ))}
            </select>
          </div>
          <div className="form-group">
            <label>Start Date *</label>
            <input type="date" required value={form.start_date} onChange={e => set('start_date', e.target.value)} />
          </div>
          <div className="form-group">
            <label>End Date *</label>
            <input type="date" required value={form.end_date} onChange={e => set('end_date', e.target.value)} />
          </div>
          <div className="form-group">
            <label>Employee *</label>
            <select required value={form.employee_id} onChange={e => set('employee_id', e.target.value)}>
              <option value="">— Choose an employee —</option>
              {employees.map(emp => (
                <option key={emp.employee_id} value={emp.employee_id}>
                  #{emp.employee_id} — {emp.full_name} ({emp.hotel_name})
                </option>
              ))}
            </select>
          </div>
        </div>
        <button className="btn btn-success" type="submit">🏨 Create Walk-In Renting</button>
      </form>
    </div>
  )
}

function ActiveRentings() {
  const [rentings, setRentings] = useState([])
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    getActiveRentings().then(setRentings).catch(console.error).finally(() => setLoading(false))
  }, [])

  if (loading) return <div className="loading-container"><div className="spinner" /><span>Loading rentings…</span></div>

  return (
    <div className="card animate-in">
      <h2>Active Rentings <span className="badge">{rentings.length}</span></h2>
      {rentings.length === 0
        ? <p className="empty">No active rentings at the moment.</p>
        : (
          <div className="table-wrap">
            <table>
              <thead>
                <tr>
                  <th>ID</th><th>Booking</th><th>Customer</th>
                  <th>Hotel</th><th>Room</th><th>Check-in</th><th>Check-out</th><th>Employee</th>
                </tr>
              </thead>
              <tbody>
                {rentings.map(r => (
                  <tr key={r.renting_id}>
                    <td><strong>#{r.renting_id}</strong></td>
                    <td>{r.booking_id ? `#${r.booking_id}` : '—'}</td>
                    <td>{r.customer_name} <small>ID: {r.customer_id}</small></td>
                    <td>{r.hotel_name}</td>
                    <td>{r.room_number}</td>
                    <td>{r.start_date}</td>
                    <td>{r.end_date}</td>
                    <td>{r.employee_name}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
    </div>
  )
}

function Payments({ showMsg }) {
  const [rentings, setRentings] = useState([])
  const [form, setForm] = useState({ renting_id: '', amount: '', method: 'cash' })
  const [payments, setPayments] = useState([])

  function loadPayments() {
    listPayments().then(setPayments).catch(console.error)
  }
  useEffect(() => {
    loadPayments()
    getActiveRentings().then(setRentings).catch(console.error)
  }, [])

  async function handleSubmit(e) {
    e.preventDefault()
    try {
      const res = await addPayment({
        renting_id: Number(form.renting_id),
        amount: Number(form.amount),
        method: form.method,
      })
      showMsg('success', `✅ Payment #${res.payment_id} recorded!`)
      setForm({ renting_id: '', amount: '', method: 'cash' })
      loadPayments()
    } catch (e) { showMsg('error', e.message) }
  }

  return (
    <div className="animate-in">
      <div className="card">
        <h2>💳 Record a Payment</h2>
        <p className="description">Insert a payment for an active renting.</p>
        <form onSubmit={handleSubmit}>
          <div className="form-grid">
            <div className="form-group">
              <label>Renting *</label>
              <select required value={form.renting_id} onChange={e => setForm(f => ({ ...f, renting_id: e.target.value }))}>
                <option value="">— Choose a renting —</option>
                {rentings.map(r => (
                  <option key={r.renting_id} value={r.renting_id}>
                    #{r.renting_id} — {r.customer_name} @ {r.hotel_name} Rm {r.room_number}
                  </option>
                ))}
              </select>
            </div>
            <div className="form-group">
              <label>Amount ($) *</label>
              <input type="number" required min="0" step="0.01" value={form.amount}
                onChange={e => setForm(f => ({ ...f, amount: e.target.value }))} placeholder="e.g. 250.00" />
            </div>
            <div className="form-group">
              <label>Method *</label>
              <select value={form.method} onChange={e => setForm(f => ({ ...f, method: e.target.value }))}>
                <option value="cash">💵 Cash</option>
                <option value="card">💳 Card</option>
                <option value="online">🌐 Online</option>
                <option value="transfer">🏦 Transfer</option>
              </select>
            </div>
          </div>
          <button className="btn btn-primary" type="submit">💳 Record Payment</button>
        </form>
      </div>

      <div className="card">
        <h2>Payment History <span className="badge">{payments.length}</span></h2>
        {payments.length === 0
          ? <p className="empty">No payments recorded yet.</p>
          : (
            <div className="table-wrap">
              <table>
                <thead>
                  <tr><th>ID</th><th>Renting</th><th>Hotel</th><th>Room</th><th>Amount</th><th>Method</th><th>Date</th></tr>
                </thead>
                <tbody>
                  {payments.map(p => (
                    <tr key={p.payment_id}>
                      <td><strong>#{p.payment_id}</strong></td>
                      <td>#{p.renting_id}</td>
                      <td>{p.hotel_name}</td>
                      <td>{p.room_number}</td>
                      <td><strong>${Number(p.amount).toFixed(2)}</strong></td>
                      <td>{p.method}</td>
                      <td>{new Date(p.paid_at).toLocaleString()}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}
      </div>
    </div>
  )
}