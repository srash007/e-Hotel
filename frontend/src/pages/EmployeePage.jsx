import { useState, useEffect } from 'react'
import {
  getActiveBookings, cancelBooking,
  checkIn, walkIn,
  getActiveRentings,
  addPayment, listPayments
} from '../api'

const TABS = ['Active Bookings', 'Check-In', 'Walk-In', 'Active Rentings', 'Payments']

export default function EmployeePage() {
  const [tab, setTab] = useState(0)
  const [msg, setMsg] = useState(null)

  function showMsg(type, text) { setMsg({ type, text }); setTimeout(() => setMsg(null), 5000) }

  return (
    <div className="page">
      <h1>👷 Employee Panel</h1>
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

// ── Active Bookings ──────────────────────────────────────────
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

  if (loading) return <p>Loading…</p>

  return (
    <div className="card">
      <h2>Active Bookings</h2>
      {bookings.length === 0
        ? <p className="empty">No active bookings.</p>
        : (
          <div className="table-wrap">
            <table>
              <thead>
                <tr>
                  <th>ID</th><th>Customer</th><th>Hotel</th><th>Room</th>
                  <th>Start</th><th>End</th><th>Status</th><th>Action</th>
                </tr>
              </thead>
              <tbody>
                {bookings.map(b => (
                  <tr key={b.booking_id}>
                    <td>#{b.booking_id}</td>
                    <td>{b.customer_name} <small>(#{b.customer_id})</small></td>
                    <td>{b.hotel_name}</td>
                    <td>{b.room_number}</td>
                    <td>{b.start_date}</td>
                    <td>{b.end_date}</td>
                    <td>{b.status}</td>
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

// ── Check-In ─────────────────────────────────────────────────
function CheckIn({ showMsg }) {
  const [form, setForm] = useState({ booking_id: '', employee_id: '' })
  const [result, setResult] = useState(null)

  async function handleSubmit(e) {
    e.preventDefault()
    setResult(null)
    try {
      const res = await checkIn(Number(form.booking_id), Number(form.employee_id))
      showMsg('success', `✅ Check-in complete! Renting #${res.renting_id} created.`)
      setResult(res)
      setForm({ booking_id: '', employee_id: '' })
    } catch (e) { showMsg('error', e.message) }
  }

  return (
    <div className="card">
      <h2>Check-In from Booking</h2>
      <p className="mt-1" style={{ color: '#555', marginBottom: '1rem' }}>
        Use this when a customer arrives with an existing booking.
      </p>
      <form onSubmit={handleSubmit}>
        <div className="form-grid">
          <div className="form-group">
            <label>Booking ID *</label>
            <input type="number" required value={form.booking_id}
              onChange={e => setForm(f => ({ ...f, booking_id: e.target.value }))}
              placeholder="e.g. 5" />
          </div>
          <div className="form-group">
            <label>Your Employee ID *</label>
            <input type="number" required value={form.employee_id}
              onChange={e => setForm(f => ({ ...f, employee_id: e.target.value }))}
              placeholder="e.g. 12" />
          </div>
        </div>
        <button className="btn btn-success" type="submit">✅ Check-In Customer</button>
      </form>
    </div>
  )
}

// ── Walk-In ───────────────────────────────────────────────────
function WalkIn({ showMsg }) {
  const [form, setForm] = useState({
    customer_id: '', room_id: '', start_date: '', end_date: '', employee_id: ''
  })

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
    <div className="card">
      <h2>Walk-In Renting (No Booking)</h2>
      <p className="mt-1" style={{ color: '#555', marginBottom: '1rem' }}>
        Use this when a customer arrives without a prior booking.
      </p>
      <form onSubmit={handleSubmit}>
        <div className="form-grid">
          <div className="form-group">
            <label>Customer ID *</label>
            <input type="number" required value={form.customer_id}
              onChange={e => set('customer_id', e.target.value)} placeholder="e.g. 3" />
          </div>
          <div className="form-group">
            <label>Room ID *</label>
            <input type="number" required value={form.room_id}
              onChange={e => set('room_id', e.target.value)} placeholder="e.g. 17" />
          </div>
          <div className="form-group">
            <label>Start Date *</label>
            <input type="date" required value={form.start_date}
              onChange={e => set('start_date', e.target.value)} />
          </div>
          <div className="form-group">
            <label>End Date *</label>
            <input type="date" required value={form.end_date}
              onChange={e => set('end_date', e.target.value)} />
          </div>
          <div className="form-group">
            <label>Your Employee ID *</label>
            <input type="number" required value={form.employee_id}
              onChange={e => set('employee_id', e.target.value)} placeholder="e.g. 12" />
          </div>
        </div>
        <button className="btn btn-success" type="submit">🏨 Create Walk-In Renting</button>
      </form>
    </div>
  )
}

// ── Active Rentings ───────────────────────────────────────────
function ActiveRentings() {
  const [rentings, setRentings] = useState([])
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    getActiveRentings().then(setRentings).catch(console.error).finally(() => setLoading(false))
  }, [])

  if (loading) return <p>Loading…</p>

  return (
    <div className="card">
      <h2>Active Rentings</h2>
      {rentings.length === 0
        ? <p className="empty">No active rentings.</p>
        : (
          <div className="table-wrap">
            <table>
              <thead>
                <tr>
                  <th>Renting ID</th><th>Booking ID</th><th>Customer</th>
                  <th>Hotel</th><th>Room</th><th>Start</th><th>End</th><th>Employee</th>
                </tr>
              </thead>
              <tbody>
                {rentings.map(r => (
                  <tr key={r.renting_id}>
                    <td>#{r.renting_id}</td>
                    <td>{r.booking_id ? `#${r.booking_id}` : '—'}</td>
                    <td>{r.customer_name} <small>(#{r.customer_id})</small></td>
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

// ── Payments ──────────────────────────────────────────────────
function Payments({ showMsg }) {
  const [form, setForm] = useState({ renting_id: '', amount: '', method: 'cash' })
  const [payments, setPayments] = useState([])

  function loadPayments() {
    listPayments().then(setPayments).catch(console.error)
  }
  useEffect(() => { loadPayments() }, [])

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
    <>
      <div className="card">
        <h2>Record a Payment</h2>
        <form onSubmit={handleSubmit}>
          <div className="form-grid">
            <div className="form-group">
              <label>Renting ID *</label>
              <input type="number" required value={form.renting_id}
                onChange={e => setForm(f => ({ ...f, renting_id: e.target.value }))} placeholder="e.g. 2" />
            </div>
            <div className="form-group">
              <label>Amount ($) *</label>
              <input type="number" required min="0" step="0.01" value={form.amount}
                onChange={e => setForm(f => ({ ...f, amount: e.target.value }))} placeholder="e.g. 250.00" />
            </div>
            <div className="form-group">
              <label>Method *</label>
              <select value={form.method} onChange={e => setForm(f => ({ ...f, method: e.target.value }))}>
                <option value="cash">Cash</option>
                <option value="card">Card</option>
                <option value="online">Online</option>
                <option value="transfer">Transfer</option>
              </select>
            </div>
          </div>
          <button className="btn btn-primary" type="submit">💳 Record Payment</button>
        </form>
      </div>

      <div className="card">
        <h2>Payment History</h2>
        {payments.length === 0
          ? <p className="empty">No payments yet.</p>
          : (
            <div className="table-wrap">
              <table>
                <thead>
                  <tr><th>ID</th><th>Renting</th><th>Hotel</th><th>Room</th><th>Amount</th><th>Method</th><th>Date</th></tr>
                </thead>
                <tbody>
                  {payments.map(p => (
                    <tr key={p.payment_id}>
                      <td>#{p.payment_id}</td>
                      <td>#{p.renting_id}</td>
                      <td>{p.hotel_name}</td>
                      <td>{p.room_number}</td>
                      <td>${Number(p.amount).toFixed(2)}</td>
                      <td>{p.method}</td>
                      <td>{new Date(p.paid_at).toLocaleString()}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}
      </div>
    </>
  )
}
