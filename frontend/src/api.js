// All API calls go here — change BASE_URL if your backend runs on a different port
const BASE_URL = 'http://localhost:8000'

async function request(method, path, body = null) {
  const opts = {
    method,
    headers: { 'Content-Type': 'application/json' },
  }
  if (body) opts.body = JSON.stringify(body)
  const res = await fetch(BASE_URL + path, opts)
  if (!res.ok) {
    const err = await res.json().catch(() => ({}))
    throw new Error(err.detail || `HTTP ${res.status}`)
  }
  return res.json()
}

// ── Search ──────────────────────────────────────────────────
export const getFilters = () => request('GET', '/search/filters')
export const searchAvailableRooms = (params) => request('POST', '/search/available-rooms', params)

// ── Bookings ─────────────────────────────────────────────────
export const createBooking = (data) => request('POST', '/bookings', data)
export const getActiveBookings = () => request('GET', '/bookings/active')
export const cancelBooking = (booking_id) => request('POST', '/bookings/cancel', { booking_id })

// ── Rentings ─────────────────────────────────────────────────
export const checkIn = (booking_id, employee_id) =>
  request('POST', '/rentings/check-in', { booking_id, employee_id })
export const walkIn = (data) => request('POST', '/rentings/walk-in', data)
export const getActiveRentings = () => request('GET', '/rentings/active')

// ── Payments ─────────────────────────────────────────────────
export const addPayment = (data) => request('POST', '/payments', data)
export const listPayments = () => request('GET', '/payments')

// ── Admin: Customers ─────────────────────────────────────────
export const createCustomer = (data) => request('POST', '/admin/customers', data)
export const updateCustomer = (id, data) => request('PATCH', `/admin/customers/${id}`, data)
export const deleteCustomer = (id) => request('DELETE', `/admin/customers/${id}`)

// ── Admin: Employees ─────────────────────────────────────────
export const createEmployee = (data) => request('POST', '/admin/employees', data)
export const deleteEmployee = (id) => request('DELETE', `/admin/employees/${id}`)

// ── Admin: Hotels ────────────────────────────────────────────
export const createHotel = (data) => request('POST', '/admin/hotels', data)
export const deleteHotel = (id) => request('DELETE', `/admin/hotels/${id}`)

// ── Admin: Rooms ─────────────────────────────────────────────
export const createRoom = (data) => request('POST', '/admin/rooms', data)
export const deleteRoom = (id) => request('DELETE', `/admin/rooms/${id}`)

// ── Admin: Views ─────────────────────────────────────────────
export const getViewAvailableRoomsPerArea = () =>
  request('GET', '/admin/views/available-rooms-per-area')
export const getViewHotelCapacity = () =>
  request('GET', '/admin/views/hotel-capacity')
