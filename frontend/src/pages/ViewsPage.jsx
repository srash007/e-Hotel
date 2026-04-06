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

  if (loading) return <div className="page"><div className="loading-container"><div className="spinner" /><span>Loading views…</span></div></div>
  if (error) return <div className="page"><div className="alert alert-error">{error}</div></div>

  const maxRooms = Math.max(...areaData.map(r => Number(r.available_rooms)), 1)

  return (
    <div className="page">
      <h1>📊 SQL Database Views</h1>
      <p className="page-subtitle">Real-time aggregated data from the database, computed via SQL Views (requirement 2f).</p>

      <div className="card animate-in">
        <h2>View 1 — Available Rooms per Area <span className="badge">SQL View</span></h2>
        <p className="description">
          Number of rooms currently available (not booked or rented for today) in each area.
        </p>
        {areaData.length === 0
          ? <p className="empty">No data available.</p>
          : (
            <>
              <div style={{ display: 'flex', flexDirection: 'column', gap: '0.6rem', marginBottom: '1.5rem' }}>
                {areaData.map(row => (
                  <div key={row.area} style={{ display: 'flex', alignItems: 'center', gap: '0.75rem' }}>
                    <span style={{ width: '140px', fontSize: '0.88rem', fontWeight: 500, color: '#475569', textAlign: 'right' }}>
                      📍 {row.area}
                    </span>
                    <div style={{ flex: 1, background: '#f1f5f9', borderRadius: '6px', overflow: 'hidden', height: '28px' }}>
                      <div style={{
                        width: `${(Number(row.available_rooms) / maxRooms) * 100}%`,
                        height: '100%',
                        background: 'linear-gradient(90deg, #2e6da4, #4a90c4)',
                        borderRadius: '6px',
                        minWidth: '32px',
                        display: 'flex',
                        alignItems: 'center',
                        justifyContent: 'flex-end',
                        paddingRight: '8px',
                        transition: 'width 0.5s ease-out'
                      }}>
                        <span style={{ color: '#fff', fontSize: '0.78rem', fontWeight: 700 }}>{row.available_rooms}</span>
                      </div>
                    </div>
                  </div>
                ))}
              </div>
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
            </>
          )}
      </div>

      <div className="card animate-in" style={{ animationDelay: '0.1s' }}>
        <h2>View 2 — Aggregated Room Capacity per Hotel <span className="badge">SQL View</span></h2>
        <p className="description">
          Total number of rooms and aggregate bed capacity (single=1, double=2, triple=3, quad=4, suite=5) per hotel.
        </p>
        {capacityData.length === 0
          ? <p className="empty">No data available.</p>
          : (
            <div className="table-wrap">
              <table>
                <thead>
                  <tr>
                    <th>ID</th>
                    <th>Hotel</th>
                    <th>Area</th>
                    <th>Rooms</th>
                    <th>Beds</th>
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
                      <td><strong>{row.hotel_name}</strong></td>
                      <td>📍 {row.area}</td>
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
