import React from 'react'
import ReactDOM from 'react-dom/client'
import { BrowserRouter, Routes, Route } from 'react-router-dom'
import App from './App.jsx'
import MeetingDetail from './MeetingDetail.jsx'
import Tasks from './Tasks.jsx' // <-- YENİ EKLENDİ
import './index.css'

ReactDOM.createRoot(document.getElementById('root')).render(
  <React.StrictMode>
    <BrowserRouter>
      <Routes>
        <Route path="/" element={<App />} />
        <Route path="/meeting/:id" element={<MeetingDetail />} />
        <Route path="/tasks" element={<Tasks />} /> {/* <-- YENİ ROTA */}
      </Routes>
    </BrowserRouter>
  </React.StrictMode>,
)