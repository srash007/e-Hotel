import { useState, useEffect } from 'react'
import { getFilters, searchAvailableRooms, createBooking } from '../api'

export default function CustomerPage() {
  const [filters, setFilters] = useState(null)
  const [form, setForm] = useState({
    start_date: '', end_date: '',
    capacity: '', area: '', chain_id: '',
    star_min: '', star_max: '',
    total_rooms_min: '', total_rooms_max: '',
    price_min: '', price_max: ''
  })
  const [rooms, setRooms] = useState([])
  const [searched, setSearched] = useState(false)
  const [loading, setLoading] = useState(false)
  const [msg, setMsg] = useState(null)

  // Booking modal state
  const [bookingModal, setBookingModal] = useState(null) // room object
  const [customerId, setCustomerId] = useState('')

  useEffect(() => {
    getFilters().then(setFilters).catch(console.error)
  }, [])

  function set(field, value) {
    setForm(f => ({ ...f, [field]: value }))
  }

  async function handleSearch(e) {
    e.preventDefault()
    if (!form.start_date || !form.end_date) {
      setMsg({ type: 'error', text: 'Please select start and end dates.' })
      return
    }
    setLoading(true)
    setMsg(null)
    try {
      const payload = {
        start_date: form.start_date,
        end_date: form.end_date,
        capacity: form.capacity || null,
        area: form.area || null,
        chain_id: form.chain_id ? Number(form.chain_id) : null,
        star_min: form.star_min ? Number(form.star_min) : null,
        star_max: form.star_max ? Number(form.star_max) : null,
        total_rooms_min: form.total_rooms_min ? Number(form.total_rooms_min) : null,
        total_rooms_max: form.total_rooms_max ? Number(form.total_rooms_max) : null,
        price_min: form.price_min ? Number(form.price_min) : null,
        price_max: form.price_max ? Number(form.price_max) : null,
      }
      const data = await searchAvailableRooms(payload)
      setRooms(data)
      setSearched(true)
    } catch (err) {
      setMsg({ type: 'error', text: err.message })
    } finally {
      setLoading(false)
    }
  }

  async function handleBook() {
    if (!customerId) { setMsg({ type: 'error', text: 'Enter your Customer ID.' }); return }
    try {
      const res = await createBooking({
        customer_id: Number(customerId),
        room_id: bookingModal.room_id,
        start_date: form.start_date,
        end_date: form.end_date,
      })
      setMsg({ type: 'success', text: `✅ Booking #${res.booking_id} created!` })
      setBookingModal(null)
      setCustomerId('')
    } catch (err) {
      setMsg({ type: 'error', text: err.message })
    }
  }

  return (
    <div className="page">
      <h1>🔍 Find Available Rooms</h1>

      {msg && <div className={`alert alert-${msg.type}`}>{msg.text}</div>}

      <div className="card">
        <form onSubmit={handleSearch}>
          <div className="form-grid">
            <div className="form-group">
              <label>Check-in Date *</label>
              <input type="date" value={form.start_date} onChange={e => set('start_date', e.target.value)} required />
            </div>
            <div className="form-group">
              <label>Check-out Date *</label>
              <input type="date" value={form.end_date} onChange={e => set('end_date', e.target.value)} required />
            </div>
            <div className="form-group">
              <label>Capacity</label>
              <select value={form.capacity} onChange={e => set('capacity', e.target.value)}>
                <option value="">Any</option>
                {filters?.capacities?.map(c => <option key={c} value={c}>{c.charAt(0).toUpperCase() + c.slice(1)}</option>)}
              </select>
            </div>
            <div className="form-group">
              <label>Area</label>
              <select value={form.area} onChange={e => set('area', e.target.value)}>
                <option value="">Any</option>
                {filters?.areas?.map(a => <option key={a} value={a}>{a}</option>)}
              </select>
            </div>
            <div className="form-group">
              <label>Hotel Chain</label>
              <select value={form.chain_id} onChange={e => set('chain_id', e.target.value)}>
                <option value="">Any</option>
                {filters?.chains?.map(c => <option key={c.chain_id} value={c.chain_id}>{c.chain_name}</option>)}
              </select>
            </div>
            <div className="form-group">
              <label>Min Stars</label>
              <select value={form.star_min} onChange={e => set('star_min', e.target.value)}>
                <option value="">Any</option>
                {[1,2,3,4,5].map(s => <option key={s} value={s}>{'⭐'.repeat(s)}</option>)}
              </select>
            </div>
            <div className="form-group">
              <label>Max Stars</label>
              <select value={form.star_max} onChange={e => set('star_max', e.target.value)}>
                <option value="">Any</option>
                {[1,2,3,4,5].map(s => <option key={s} value={s}>{'⭐'.repeat(s)}</option>)}
              </select>
            </div>
            <div className="form-group">
              <label>Min Rooms in Hotel</label>
              <input type="number" min="0" value={form.total_rooms_min} onChange={e => set('total_rooms_min', e.target.value)} placeholder="e.g. 5" />
            </div>
            <div className="form-group">
              <label>Max Rooms in Hotel</label>
              <input type="number" min="0" value={form.total_rooms_max} onChange={e => set('total_rooms_max', e.target.value)} placeholder="e.g. 50" />
            </div>
            <div className="form-group">
              <label>Min Price / Night ($)</label>
              <input type="number" min="0" value={form.price_min} onChange={e => set('price_min', e.target.value)} placeholder="0" />
            </div>
            <div className="form-group">
              <label>Max Price / Night ($)</label>
              <input type="number" min="0" value={form.price_max} onChange={e => set('price_max', e.target.value)} placeholder="500" />
            </div>
          </div>
          <button className="btn btn-primary" type="submit" disabled={loading}>
            {loading ? 'Searching…' : '🔍 Search'}
          </button>
        </form>
      </div>

      {searched && (
        <>
          <h2>{rooms.length} room{rooms.length !== 1 ? 's' : ''} found</h2>
          {rooms.length === 0
            ? <p className="empty">No rooms available for those criteria.</p>
            : (
              <div className="room-grid">
                {rooms.map(r => (
                  <div className="room-card" key={r.room_id}>
                    <h3>Room {r.room_number} — {r.hotel_name}</h3>
                    <p>🏨 {r.chain_name} &nbsp;|&nbsp; {'⭐'.repeat(r.star_rating)}</p>
                    <p>📍 {r.area}</p>
                    <p>🛏 {r.capacity} &nbsp;|&nbsp; 👁 View: {r.view_type}</p>
                    <p>🏠 Total rooms in hotel: {r.total_rooms}</p>
                    {r.extendable && <p>✅ Extendable</p>}
                    <p className="price">${Number(r.price_per_night).toFixed(2)} / night</p>
                    <button className="btn btn-success" onClick={() => { setBookingModal(r); setMsg(null) }}>
                      Book this room
                    </button>
                  </div>
                ))}
              </div>
            )
          }
        </>
      )}

      {bookingModal && (
        <div className="modal-overlay">
          <div className="modal">
            <h2>📋 Confirm Booking</h2>
            <p><strong>Room:</strong> {bookingModal.room_number} — {bookingModal.hotel_name}</p>
            <p><strong>Dates:</strong> {form.start_date} → {form.end_date}</p>
            <p><strong>Price:</strong> ${Number(bookingModal.price_per_night).toFixed(2)} / night</p>
            <div className="form-group mt-2">
              <label>Your Customer ID</label>
              <input type="number" value={customerId} onChange={e => setCustomerId(e.target.value)} placeholder="Enter your customer ID" />
            </div>
            <div className="modal-actions">
              <button className="btn btn-warning" onClick={() => setBookingModal(null)}>Cancel</button>
              <button className="btn btn-success" onClick={handleBook}>✅ Confirm Booking</button>
            </div>
          </div>
        </div>
      )}
    </div>
  )
}
