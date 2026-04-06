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

export const getFilters = () => request('GET', '/search/filters')
export const searchAvailableRooms = (params) => request('POST', '/search/available-rooms', params)

export const createBooking = (data) => request('POST', '/bookings', data)
export const getActiveBookings = () => request('GET', '/bookings/active')
export const cancelBooking = (booking_id) => request('POST', '/bookings/cancel', { booking_id })

export const checkIn = (booking_id, employee_id) =>
  request('POST', '/rentings/check-in', { booking_id, employee_id })
export const walkIn = (data) => request('POST', '/rentings/walk-in', data)
export const getActiveRentings = () => request('GET', '/rentings/active')

export const addPayment = (data) => request('POST', '/payments', data)
export const listPayments = () => request('GET', '/payments')

export const listCustomers = () => request('GET', '/admin/customers')
export const createCustomer = (data) => request('POST', '/admin/customers', data)
export const updateCustomer = (id, data) => request('PATCH', `/admin/customers/${id}`, data)
export const deleteCustomer = (id) => request('DELETE', `/admin/customers/${id}`)

export const listEmployees = () => request('GET', '/admin/employees')
export const createEmployee = (data) => request('POST', '/admin/employees', data)
export const updateEmployee = (id, data) => request('PATCH', `/admin/employees/${id}`, data)
export const deleteEmployee = (id) => request('DELETE', `/admin/employees/${id}`)

export const listHotels = () => request('GET', '/admin/hotels')
export const createHotel = (data) => request('POST', '/admin/hotels', data)
export const updateHotel = (id, data) => request('PATCH', `/admin/hotels/${id}`, data)
export const deleteHotel = (id) => request('DELETE', `/admin/hotels/${id}`)

export const listRooms = () => request('GET', '/admin/rooms')
export const createRoom = (data) => request('POST', '/admin/rooms', data)
export const updateRoom = (id, data) => request('PATCH', `/admin/rooms/${id}`, data)
export const deleteRoom = (id) => request('DELETE', `/admin/rooms/${id}`)


export const getViewAvailableRoomsPerArea = () =>
  request('GET', '/admin/views/available-rooms-per-area')
export const getViewHotelCapacity = () =>
  request('GET', '/admin/views/hotel-capacity')

export const listChains = () =>
  getFilters().then(f => f.chains || [])
