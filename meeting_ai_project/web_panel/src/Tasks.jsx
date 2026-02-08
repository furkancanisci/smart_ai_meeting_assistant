import { useState, useEffect } from 'react'
import { useNavigate } from 'react-router-dom'
import axios from 'axios'
import { ArrowLeftIcon, FunnelIcon, CalendarIcon, UserCircleIcon } from '@heroicons/react/24/outline'

const API_URL = "http://127.0.0.1:8000/api/v1";

export default function Tasks() {
  const navigate = useNavigate()
  const [tasks, setTasks] = useState([])
  const [filter, setFilter] = useState("") // İsim filtresi
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    fetchTasks();
  }, [])

  const fetchTasks = async () => {
    try {
      const response = await axios.get(`${API_URL}/meetings/tasks/all`);
      setTasks(response.data);
      setLoading(false);
    } catch (error) {
      console.error("Görevler yüklenemedi:", error);
      setLoading(false);
    }
  }

  // Filtreleme Mantığı
  const filteredTasks = tasks.filter(task => 
    task.assignee?.toLowerCase().includes(filter.toLowerCase()) ||
    task.description?.toLowerCase().includes(filter.toLowerCase())
  )

  // Tarih Kontrolü (Gecikmiş mi?)
  const isOverdue = (dateString) => {
    if (!dateString) return false;
    const due = new Date(dateString);
    const now = new Date();
    return due < now; // Tarih geçmişse true
  }

  return (
    <div className="min-h-screen bg-gray-50 p-8 font-sans text-gray-900">
      <div className="max-w-6xl mx-auto">
        
        {/* ÜST BAR */}
        <div className="flex justify-between items-center mb-8">
            <button onClick={() => navigate('/')} className="flex items-center text-gray-500 hover:text-indigo-600 transition">
                <ArrowLeftIcon className="h-5 w-5 mr-2"/>
                Dashboard'a Dön
            </button>
            <h1 className="text-2xl font-bold text-gray-800">Tüm Görevler Merkezi</h1>
        </div>

        {/* FİLTRE ALANI */}
        <div className="bg-white p-4 rounded-2xl shadow-sm border border-gray-100 mb-6 flex gap-4 items-center">
            <FunnelIcon className="h-5 w-5 text-gray-400"/>
            <input 
                type="text" 
                placeholder="İsim veya görev ara (Örn: Ali, Rapor)..." 
                className="w-full outline-none text-gray-700 bg-transparent"
                value={filter}
                onChange={(e) => setFilter(e.target.value)}
            />
        </div>

        {/* TABLO */}
        <div className="bg-white rounded-2xl shadow-sm border border-gray-100 overflow-hidden">
            <table className="w-full text-left border-collapse">
                <thead className="bg-gray-50 text-gray-500 text-xs uppercase font-semibold">
                    <tr>
                        <th className="px-6 py-4">Görev</th>
                        <th className="px-6 py-4">Sorumlu</th>
                        <th className="px-6 py-4">Son Tarih</th>
                        <th className="px-6 py-4">Kaynak Toplantı</th>
                        <th className="px-6 py-4 text-right">İşlem</th>
                    </tr>
                </thead>
                <tbody className="divide-y divide-gray-100">
                    {filteredTasks.map((task) => (
                        <tr key={task.id} className="hover:bg-gray-50 transition group">
                            <td className="px-6 py-4 font-medium text-gray-900">
                                {task.description}
                            </td>
                            <td className="px-6 py-4">
                                <div className="flex items-center gap-2">
                                    <UserCircleIcon className="h-5 w-5 text-indigo-400"/>
                                    <span className="text-sm text-gray-700 font-medium">{task.assignee || "Belirsiz"}</span>
                                </div>
                            </td>
                            <td className="px-6 py-4">
                                {task.due_date ? (
                                    <span className={`text-xs px-2 py-1 rounded font-medium flex items-center w-max gap-1
                                        ${isOverdue(task.due_date) ? 'bg-red-100 text-red-700' : 'bg-blue-50 text-blue-700'}
                                    `}>
                                        <CalendarIcon className="h-3 w-3"/>
                                        {task.due_date}
                                        {isOverdue(task.due_date) && " (Gecikti)"}
                                    </span>
                                ) : (
                                    <span className="text-gray-400 text-xs">-</span>
                                )}
                            </td>
                            <td className="px-6 py-4 text-sm text-gray-500">
                                {task.meeting_title}
                            </td>
                            <td className="px-6 py-4 text-right">
                                <button 
                                    onClick={() => navigate(`/meeting/${task.meeting_id}`)}
                                    className="text-xs font-bold text-indigo-600 hover:underline"
                                >
                                    Kaynağa Git
                                </button>
                            </td>
                        </tr>
                    ))}
                    {filteredTasks.length === 0 && (
                        <tr>
                            <td colSpan="5" className="p-8 text-center text-gray-400">
                                Aradığınız kriterlere uygun görev bulunamadı.
                            </td>
                        </tr>
                    )}
                </tbody>
            </table>
        </div>

      </div>
    </div>
  )
}