import { useState, useEffect } from 'react'
import { getViewAvailableRoomsPerArea, getViewHotelCapacity } from '../api'

export default function ViewsPage() {
  const [areaData, setAreaData] = useState([])
  const [capacityData, setCapacityData] = useState([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState(null)

  useEffect(() => {
    Promise.all([getViewAvailableRoomsPerArea(), getViewHotelCapacity()])
      .then(([areas, caps]) => { setAreaData(areas); setCapacityData(caps) })
      .catch(e => setError(e.message))
      .finally(() => setLoading(false))
  }, [])

  if (loading) return <div className="page"><p>Loading views…</p></div>
  if (error) return <div className="page"><div className="alert alert-error">{error}</div></div>

  return (
    <div className="page">
      <h1>📊 Database Views</h1>

      {/* View 1 */}
      <div className="card">
        <h2>View 1 — Available Rooms per Area (today)</h2>
        <p style={{ color: '#555', marginBottom: '1rem', fontSize: '0.9rem' }}>
          Shows the number of rooms that are currently available (not booked or rented for today) in each area.
        </p>
        {areaData.length === 0
          ? <p className="empty">No data available.</p>
          : (
            <div className="table-wrap">
              <table>
                <thead>
                  <tr><th>Area</th><th>Available Rooms</th></tr>
                </thead>
                <tbody>
                  {areaData.map(row => (
                    <tr key={row.area}>
                      <td>📍 {row.area}</td>
                      <td><strong>{row.available_rooms}</strong></td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}
      </div>

      {/* View 2 */}
      <div className="card">
        <h2>View 2 — Aggregated Room Capacity per Hotel</h2>
        <p style={{ color: '#555', marginBottom: '1rem', fontSize: '0.9rem' }}>
          Shows the total number of rooms and aggregate bed capacity (single=1, double=2, triple=3, quad=4, suite=5) per hotel.
        </p>
        {capacityData.length === 0
          ? <p className="empty">No data available.</p>
          : (
            <div className="table-wrap">
              <table>
                <thead>
                  <tr>
                    <th>Hotel ID</th>
                    <th>Hotel Name</th>
                    <th>Area</th>
                    <th>Total Rooms</th>
                    <th>Beds (Aggregated)</th>
                    <th>Single</th>
                    <th>Double</th>
                    <th>Triple</th>
                    <th>Quad</th>
                    <th>Suite</th>
                  </tr>
                </thead>
                <tbody>
                  {capacityData.map(row => (
                    <tr key={row.hotel_id}>
                      <td>#{row.hotel_id}</td>
                      <td>{row.hotel_name}</td>
                      <td>{row.area}</td>
                      <td><strong>{row.total_rooms}</strong></td>
                      <td><strong>{row.aggregated_capacity_beds}</strong></td>
                      <td>{row.num_single}</td>
                      <td>{row.num_double}</td>
                      <td>{row.num_triple}</td>
                      <td>{row.num_quad}</td>
                      <td>{row.num_suite}</td>
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
