import { Routes, Route, Link, Navigate } from 'react-router-dom'
import { useState } from 'react'

const API_URL = import.meta.env.VITE_API_URL || ''

function Login({ setToken }) {
  const [username, setUsername] = useState('')
  const [error, setError] = useState('')

  const handleSubmit = async (e) => {
    e.preventDefault()
    try {
      const res = await fetch(`${API_URL}/login`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ username })
      })
      const data = await res.json()
      if (data.token) {
        localStorage.setItem('token', data.token)
        setToken(data.token)
      } else {
        setError(data.error || 'Login failed')
      }
    } catch {
      setError('Connection error')
    }
  }

  return (
    <div className="container">
      <h1>Login</h1>
      <form onSubmit={handleSubmit} className="card">
        {error && <p className="error">{error}</p>}
        <input
          type="text"
          placeholder="Username"
          value={username}
          onChange={(e) => setUsername(e.target.value)}
        />
        <button type="submit">Login</button>
      </form>
    </div>
  )
}

function Books({ token }) {
  const [books, setBooks] = useState([])
  const [name, setName] = useState('')
  const [error, setError] = useState('')

  const fetchBooks = async () => {
    try {
      const res = await fetch(`${API_URL}/books`)
      const data = await res.json()
      setBooks(data)
    } catch {
      setError('Failed to load books')
    }
  }

  const addBook = async (e) => {
    e.preventDefault()
    try {
      await fetch(`${API_URL}/books`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ name })
      })
      setName('')
      fetchBooks()
    } catch {
      setError('Failed to add book')
    }
  }

  useState(() => {
    fetchBooks()
  }, [])

  return (
    <div className="container">
      <h1>Books</h1>
      {error && <p className="error">{error}</p>}
      <form onSubmit={addBook} className="card">
        <input
          type="text"
          placeholder="Book name"
          value={name}
          onChange={(e) => setName(e.target.value)}
        />
        <button type="submit">Add Book</button>
      </form>
      <ul>
        {books.map((book, i) => (
          <li key={i}>{book.name}</li>
        ))}
      </ul>
    </div>
  )
}

export default function App() {
  const [token, setToken] = useState(() => localStorage.getItem('token'))

  const logout = () => {
    localStorage.removeItem('token')
    setToken(null)
  }

  return (
    <>
      <nav>
        <Link to="/">Home</Link>
        {token ? (
          <>
            <Link to="/books">Books</Link>
            <button onClick={logout} style={{background:'#dc3545'}}>Logout</button>
          </>
        ) : (
          <Link to="/login">Login</Link>
        )}
      </nav>
      <Routes>
        <Route path="/" element={
          <div className="container"><h1>Welcome to MERN App</h1></div>
        } />
        <Route path="/login" element={token ? <Navigate to="/books" /> : <Login setToken={setToken} />} />
        <Route path="/books" element={token ? <Books token={token} /> : <Navigate to="/login" />} />
      </Routes>
    </>
  )
}
