import { useState, useEffect, useRef, useMemo } from 'react'
import { getFilters, searchAvailableRooms, createBooking, listCustomers, createCustomer } from '../api'
import heroImg from '../assets/hero-hotel.jpg'

const INITIAL_FORM = {
  start_date: '', end_date: '',
  capacity: '', area: '', chain_id: '',
  star_min: '', star_max: '',
  total_rooms_min: '', total_rooms_max: '',
  price_min: '', price_max: ''
}

export default function CustomerPage() {
  const [filters, setFilters] = useState(null)
  const [form, setForm] = useState({ ...INITIAL_FORM })
  const [rooms, setRooms] = useState([])
  const [searched, setSearched] = useState(false)
  const [loading, setLoading] = useState(false)
  const [msg, setMsg] = useState(null)
  const [bookingModal, setBookingModal] = useState(null)

  // Customer selection state
  const [customers, setCustomers] = useState([])
  const [selectedCustomerId, setSelectedCustomerId] = useState('')
  const [customerSearch, setCustomerSearch] = useState('')
  const [showCreateCustomer, setShowCreateCustomer] = useState(false)
  const [newCustomer, setNewCustomer] = useState({
    full_name: '', street: '', city: '', country: '', state: '', postal_code: '',
    id_type: 'SIN', id_value: ''
  })

  const filteredCustomers = useMemo(() => {
    if (!customerSearch.trim()) return customers
    const q = customerSearch.toLowerCase()
    return customers.filter(c =>
      c.full_name.toLowerCase().includes(q) ||
      c.city?.toLowerCase().includes(q) ||
      c.id_value?.toLowerCase().includes(q) ||
      String(c.customer_id).includes(q)
    )
  }, [customers, customerSearch])

  // Compute active filter labels for visual display
  const activeFilters = useMemo(() => {
    const tags = []
    if (form.start_date && form.end_date) tags.push({ key: 'dates', label: `📅 ${form.start_date} → ${form.end_date}`, fields: ['start_date', 'end_date'] })
    if (form.capacity) tags.push({ key: 'capacity', label: `🛏 ${form.capacity}`, fields: ['capacity'] })
    if (form.area) tags.push({ key: 'area', label: `📍 ${form.area}`, fields: ['area'] })
    if (form.chain_id && filters?.chains) {
      const ch = filters.chains.find(c => String(c.chain_id) === String(form.chain_id))
      tags.push({ key: 'chain', label: `🏨 ${ch?.chain_name || form.chain_id}`, fields: ['chain_id'] })
    }
    if (form.star_min || form.star_max) {
      const mn = form.star_min || '1', mx = form.star_max || '5'
      tags.push({ key: 'stars', label: `⭐ ${mn}–${mx} stars`, fields: ['star_min', 'star_max'] })
    }
    if (form.total_rooms_min || form.total_rooms_max) {
      tags.push({ key: 'rooms', label: `🏠 ${form.total_rooms_min || '0'}–${form.total_rooms_max || '∞'} rooms`, fields: ['total_rooms_min', 'total_rooms_max'] })
    }
    if (form.price_min || form.price_max) {
      tags.push({ key: 'price', label: `💰 $${form.price_min || '0'}–$${form.price_max || '∞'}`, fields: ['price_min', 'price_max'] })
    }
    return tags
  }, [form, filters])

  function clearFilter(fields) {
    setForm(f => {
      const updated = { ...f }
      fields.forEach(k => updated[k] = '')
      if (updated.start_date && updated.end_date) {
        clearTimeout(debounceRef.current)
        debounceRef.current = setTimeout(() => doSearch(updated), 400)
      }
      return updated
    })
  }

  function clearAllFilters() {
    setForm({ ...INITIAL_FORM })
    setRooms([])
    setSearched(false)
  }

  // Dynamic filtering debounce
  const debounceRef = useRef(null)

  useEffect(() => {
    getFilters().then(setFilters).catch(console.error)
    listCustomers().then(setCustomers).catch(console.error)
  }, [])

  function set(field, value) {
    setForm(f => {
      const updated = { ...f, [field]: value }
      // Dynamic filtering: auto-search if dates are set
      if (updated.start_date && updated.end_date) {
        clearTimeout(debounceRef.current)
        debounceRef.current = setTimeout(() => doSearch(updated), 400)
      }
      return updated
    })
  }

  async function doSearch(f) {
    setLoading(true)
    setMsg(null)
    try {
      const payload = {
        start_date: f.start_date,
        end_date: f.end_date,
        capacity: f.capacity || null,
        area: f.area || null,
        chain_id: f.chain_id ? Number(f.chain_id) : null,
        star_min: f.star_min ? Number(f.star_min) : null,
        star_max: f.star_max ? Number(f.star_max) : null,
        total_rooms_min: f.total_rooms_min ? Number(f.total_rooms_min) : null,
        total_rooms_max: f.total_rooms_max ? Number(f.total_rooms_max) : null,
        price_min: f.price_min ? Number(f.price_min) : null,
        price_max: f.price_max ? Number(f.price_max) : null,
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

  async function handleSearch(e) {
    e.preventDefault()
    if (!form.start_date || !form.end_date) {
      setMsg({ type: 'error', text: '📅 Please select both check-in and check-out dates.' })
      return
    }
    doSearch(form)
  }

  async function handleBook() {
    if (!selectedCustomerId) { setMsg({ type: 'error', text: 'Please select a customer.' }); return }
    try {
      const res = await createBooking({
        customer_id: Number(selectedCustomerId),
        room_id: bookingModal.room_id,
        start_date: form.start_date,
        end_date: form.end_date,
      })
      setMsg({ type: 'success', text: `✅ Booking #${res.booking_id} created successfully!` })
      setBookingModal(null)
      setSelectedCustomerId('')
    } catch (err) {
      setMsg({ type: 'error', text: err.message })
    }
  }

  async function handleCreateCustomer(e) {
    e.preventDefault()
    try {
      const res = await createCustomer(newCustomer)
      setMsg({ type: 'success', text: `✅ Customer created! ID: ${res.customer_id}` })
      setSelectedCustomerId(String(res.customer_id))
      setShowCreateCustomer(false)
      setNewCustomer({ full_name: '', street: '', city: '', country: '', state: '', postal_code: '', id_type: 'SIN', id_value: '' })
      // Refresh customers list
      const updated = await listCustomers()
      setCustomers(updated)
    } catch (err) {
      setMsg({ type: 'error', text: err.message })
    }
  }

  return (
    <div>
      {/* Hero Section */}
      <div className="hero-section">
        <img src={heroImg} alt="Luxury hotel lobby" className="hero-image" width={1920} height={640} />
        <div className="hero-overlay" />
        <div className="hero-content">
          <h1 className="hero-title">Find Your Perfect Stay</h1>
          <p className="hero-subtitle">Search across all hotel chains to find the best available rooms at the best prices.</p>
        </div>
      </div>

      <div className="page">
        {msg && <div className={`alert alert-${msg.type}`}>{msg.text}</div>}

        <div className="card">
          <h2>🔍 Search Criteria</h2>
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
                <label>Room Capacity</label>
                <select value={form.capacity} onChange={e => set('capacity', e.target.value)}>
                  <option value="">Any</option>
                  {filters?.capacities?.map(c => <option key={c} value={c}>{c.charAt(0).toUpperCase() + c.slice(1)}</option>)}
                </select>
              </div>
              <div className="form-group">
                <label>Area / Location</label>
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
                <input type="number" min="0" value={form.price_min} onChange={e => set('price_min', e.target.value)} placeholder="$0" />
              </div>
              <div className="form-group">
                <label>Max Price / Night ($)</label>
                <input type="number" min="0" value={form.price_max} onChange={e => set('price_max', e.target.value)} placeholder="$500" />
              </div>
            </div>
            <div style={{ display: 'flex', gap: '0.5rem', flexWrap: 'wrap', alignItems: 'center' }}>
              <button className="btn btn-primary btn-lg" type="submit" disabled={loading}>
                {loading ? '⏳ Searching…' : '🔍 Search Available Rooms'}
              </button>
              {activeFilters.length > 0 && (
                <button type="button" className="btn btn-outline btn-sm" onClick={clearAllFilters}>
                  ✕ Clear All
                </button>
              )}
            </div>

            {/* Active filter chips */}
            {activeFilters.length > 0 && (
              <div className="active-filters" style={{ display: 'flex', gap: '0.4rem', flexWrap: 'wrap', marginTop: '0.75rem' }}>
                {activeFilters.map(f => (
                  <span key={f.key} className="filter-chip" onClick={() => clearFilter(f.fields)}
                    style={{
                      display: 'inline-flex', alignItems: 'center', gap: '0.35rem',
                      background: 'var(--primary)', color: '#fff',
                      padding: '0.3rem 0.7rem', borderRadius: '999px',
                      fontSize: '0.8rem', fontWeight: 500, cursor: 'pointer',
                      transition: 'opacity var(--transition)'
                    }}
                    title="Click to remove"
                    onMouseEnter={e => e.currentTarget.style.opacity = '0.8'}
                    onMouseLeave={e => e.currentTarget.style.opacity = '1'}
                  >
                    {f.label} <span style={{ fontWeight: 700, marginLeft: '0.15rem' }}>×</span>
                  </span>
                ))}
              </div>
            )}
          </form>
        </div>

        {searched && (
          <div className="animate-in">
            <div className="results-header">
              <h2>Available Rooms</h2>
              <span className="results-count">{rooms.length} room{rooms.length !== 1 ? 's' : ''} found</span>
            </div>
            {rooms.length === 0
              ? (
                <div className="card" style={{ textAlign: 'center', padding: '3rem 1.5rem' }}>
                  <div style={{ fontSize: '3rem', marginBottom: '0.75rem' }}>🏨</div>
                  <h3 style={{ marginBottom: '0.5rem', color: 'var(--text)' }}>No rooms available</h3>
                  <p style={{ color: 'var(--text-secondary)', marginBottom: '1rem' }}>No rooms match your current filters. Try broadening your search.</p>
                  {activeFilters.length > 1 && (
                    <button className="btn btn-outline btn-sm" onClick={clearAllFilters}>
                      ✕ Clear all filters and start over
                    </button>
                  )}
                </div>
              )
              : (
                <div className="room-grid">
                  {rooms.map((r, i) => (
                    <div className="room-card" key={r.room_id} style={{ animationDelay: `${i * 0.05}s` }}>
                      <h3>Room {r.room_number} — {r.hotel_name}</h3>
                      <div className="room-amenities">
                        <span className="amenity-tag">🏨 {r.chain_name}</span>
                        <span className="amenity-tag">{'⭐'.repeat(r.star_rating)}</span>
                        <span className="amenity-tag">📍 {r.area}</span>
                      </div>
                      <p>🛏 {r.capacity} &nbsp;|&nbsp; 👁 {r.view_type} view</p>
                      <p>🏠 {r.total_rooms} rooms in hotel</p>
                      {r.extendable && <span className="amenity-tag" style={{ display: 'inline-block', marginTop: '0.25rem' }}>✅ Extendable</span>}
                      <p className="price">${Number(r.price_per_night).toFixed(2)} <span>/ night</span></p>
                      <button className="btn btn-success" style={{ width: '100%' }} onClick={() => { setBookingModal(r); setMsg(null) }}>
                        Book this room
                      </button>
                    </div>
                  ))}
                </div>
              )
            }
          </div>
        )}

        {/* Booking Modal with customer selection */}
        {bookingModal && (
          <div className="modal-overlay" onClick={() => setBookingModal(null)}>
            <div className="modal" onClick={e => e.stopPropagation()} style={{ maxWidth: 520 }}>
              <h2>📋 Confirm Booking</h2>
              <div className="description">
                <p><strong>Room:</strong> {bookingModal.room_number} — {bookingModal.hotel_name}</p>
                <p><strong>Dates:</strong> {form.start_date} → {form.end_date}</p>
                <p><strong>Price:</strong> ${Number(bookingModal.price_per_night).toFixed(2)} / night</p>
              </div>

              <div className="form-group">
                <label>Search Customer</label>
                <input
                  type="text"
                  placeholder="Search by name, city, or ID…"
                  value={customerSearch}
                  onChange={e => setCustomerSearch(e.target.value)}
                  autoFocus
                />
              </div>
              <div className="form-group">
                <label>Select Customer * <small style={{ fontWeight: 400, textTransform: 'none' }}>({filteredCustomers.length} found)</small></label>
                <select value={selectedCustomerId} onChange={e => setSelectedCustomerId(e.target.value)}>
                  <option value="">— Choose a customer —</option>
                  {filteredCustomers.map(c => (
                    <option key={c.customer_id} value={c.customer_id}>
                      #{c.customer_id} — {c.full_name} ({c.city}, {c.country})
                    </option>
                  ))}
                </select>
              </div>

              <button className="btn btn-outline btn-sm" style={{ marginBottom: '1rem' }}
                onClick={() => setShowCreateCustomer(!showCreateCustomer)}>
                {showCreateCustomer ? '▲ Hide' : '➕ New Customer'}
              </button>

              {showCreateCustomer && (
                <form onSubmit={handleCreateCustomer} style={{ background: 'var(--border-light)', padding: '1rem', borderRadius: 'var(--radius-sm)', marginBottom: '1rem' }}>
                  <div className="form-grid" style={{ gridTemplateColumns: '1fr 1fr' }}>
                    <div className="form-group"><label>Full Name *</label>
                      <input required value={newCustomer.full_name} onChange={e => setNewCustomer(p => ({ ...p, full_name: e.target.value }))} placeholder="John Doe" /></div>
                    <div className="form-group"><label>Street *</label>
                      <input required value={newCustomer.street} onChange={e => setNewCustomer(p => ({ ...p, street: e.target.value }))} placeholder="123 Main St" /></div>
                    <div className="form-group"><label>City *</label>
                      <input required value={newCustomer.city} onChange={e => setNewCustomer(p => ({ ...p, city: e.target.value }))} placeholder="Ottawa" /></div>
                    <div className="form-group"><label>State</label>
                      <input value={newCustomer.state} onChange={e => setNewCustomer(p => ({ ...p, state: e.target.value }))} placeholder="Ontario" /></div>
                    <div className="form-group"><label>Country *</label>
                      <input required value={newCustomer.country} onChange={e => setNewCustomer(p => ({ ...p, country: e.target.value }))} placeholder="Canada" /></div>
                    <div className="form-group"><label>Postal Code</label>
                      <input value={newCustomer.postal_code} onChange={e => setNewCustomer(p => ({ ...p, postal_code: e.target.value }))} placeholder="K1A 0A1" /></div>
                    <div className="form-group"><label>ID Type *</label>
                      <select value={newCustomer.id_type} onChange={e => setNewCustomer(p => ({ ...p, id_type: e.target.value }))}>
                        <option value="SSN">SSN</option><option value="SIN">SIN</option>
                        <option value="DRIVER_LICENCE">Driver's Licence</option><option value="PASSPORT">Passport</option>
                      </select></div>
                    <div className="form-group"><label>ID Value *</label>
                      <input required value={newCustomer.id_value} onChange={e => setNewCustomer(p => ({ ...p, id_value: e.target.value }))} placeholder="123-456-789" /></div>
                  </div>
                  <button className="btn btn-success btn-sm" type="submit">✅ Create & Select</button>
                </form>
              )}

              <div className="modal-actions">
                <button className="btn btn-outline" onClick={() => setBookingModal(null)}>Cancel</button>
                <button className="btn btn-success" onClick={handleBook}>✅ Confirm Booking</button>
              </div>
            </div>
          </div>
        )}
      </div>
    </div>
  )
}
