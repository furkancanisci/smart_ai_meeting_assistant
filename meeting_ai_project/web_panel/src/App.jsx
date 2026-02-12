import { useState, useEffect } from 'react'
import axios from 'axios'
import { useNavigate } from 'react-router-dom' // <-- EKLE
// diğer importlar...
import { 
  CalendarIcon, 
  ClockIcon, 
  CheckCircleIcon, 
  ArrowPathIcon,
  BriefcaseIcon,
  ChartBarIcon 
} from '@heroicons/react/24/outline'

const API_URL = "http://127.0.0.1:8000/api/v1"; 

function App() {
  const [meetings, setMeetings] = useState([])
  const [loading, setLoading] = useState(true)
  const navigate = useNavigate() // <-- EKLE
  // ...
  const [stats, setStats] = useState({
    totalMeetings: 0,
    totalTasks: 0,
    totalDuration: 0 // Saniye cinsinden
  })

  const fetchMeetings = async () => {
    try {
      setLoading(true);
      const response = await axios.get(`${API_URL}/meetings/`);
      const data = response.data;
      
      setMeetings(data);

      // --- İSTATİSTİKLERİ HESAPLA ---
      let taskCount = 0;
      let durationSum = 0;

      data.forEach(meeting => {
        // Backend'den gelen action_items listesinin uzunluğu
        if (meeting.action_items) {
          taskCount += meeting.action_items.length;
        }
        if (meeting.duration_seconds) {
          durationSum += meeting.duration_seconds;
        }
      });

      setStats({
        totalMeetings: data.length,
        totalTasks: taskCount,
        totalDuration: durationSum
      });
      
    } catch (error) {
      console.error("Veri çekme hatası:", error);
    } finally {
      setLoading(false);
    }
  }

  useEffect(() => {
    fetchMeetings();
  }, [])

  // Saniyeyi "1s 30dk" formatına çeviren yardımcı fonksiyon
  const formatDuration = (seconds) => {
    if (!seconds) return "0 dk";
    const h = Math.floor(seconds / 3600);
    const m = Math.floor((seconds % 3600) / 60);
    if (h > 0) return `${h}sa ${m}dk`;
    return `${m}dk`;
  }

  return (
    <div className="min-h-screen bg-gray-50 font-sans text-gray-900">
      
      {/* ÜST BAR (NAVBAR) */}
      <nav className="bg-white border-b border-gray-200 px-8 py-4 flex justify-between items-center sticky top-0 z-10">
        <div className="flex items-center gap-2">
          <div className="bg-indigo-600 p-2 rounded-lg">
            <ChartBarIcon className="h-6 w-6 text-white" />
          </div>
          <h1 className="text-xl font-bold text-gray-800 tracking-tight">Smart AI Meeting Assistant <span className="text-indigo-600">Admin</span></h1>
        </div>
        <div className="flex gap-4">
           <button onClick={fetchMeetings} className="p-2 text-gray-500 hover:text-indigo-600 transition bg-gray-100 rounded-full">
            <ArrowPathIcon className={`h-5 w-5 ${loading ? 'animate-spin' : ''}`}/>
          </button>
          <div className="h-10 w-10 bg-indigo-100 rounded-full flex items-center justify-center text-indigo-700 font-bold border border-indigo-200">
            YC
          </div>
        </div>
      </nav>

      <main className="max-w-7xl mx-auto p-8">
        
        {/* BAŞLIK VE BUTON */}
        <div className="flex justify-between items-end mb-8">
          <div>
            <h2 className="text-3xl font-bold text-gray-900">Genel Bakış</h2>
            <p className="text-gray-500 mt-1">İşletmenizin toplantı ve görev performans takibi.</p>
          </div>
          <button className="bg-indigo-600 hover:bg-indigo-700 text-white px-5 py-2.5 rounded-xl font-medium shadow-lg shadow-indigo-200 transition-all flex items-center gap-2">
            <span>+ Manuel Ekle</span>
          </button>
        </div>

        {/* İSTATİSTİK KARTLARI (DİNAMİK) */}
        <div className="grid grid-cols-1 md:grid-cols-3 gap-6 mb-10">
          
          {/* Kart 1: Toplantılar */}
          <div className="bg-white p-6 rounded-2xl shadow-sm border border-gray-100 hover:shadow-md transition-shadow">
            <div className="flex justify-between items-start">
              <div>
                <p className="text-sm font-medium text-gray-400 uppercase tracking-wider">Toplam Toplantı</p>
                <h3 className="text-3xl font-bold text-gray-900 mt-2">{stats.totalMeetings}</h3>
              </div>
              <div className="p-3 bg-blue-50 rounded-xl">
                <BriefcaseIcon className="h-6 w-6 text-blue-600"/>
              </div>
            </div>
            <div className="mt-4 flex items-center text-sm text-green-600 bg-green-50 w-max px-2 py-1 rounded-md">
              <span className="font-medium">Aktif</span>
            </div>
          </div>

          {/* Kart 2: Görevler */}
          <div className="bg-white p-6 rounded-2xl shadow-sm border border-gray-100 hover:shadow-md transition-shadow">
             <div className="flex justify-between items-start">
              <div 
                onClick={() => navigate('/tasks')} // <-- BU SATIR EKLENDİ
                className="bg-white p-6 rounded-2xl shadow-sm border border-gray-100 hover:shadow-md transition-shadow cursor-pointer" // cursor-pointer ekledik
              >
                
                <p className="text-sm font-medium text-gray-400 uppercase tracking-wider">Çıkarılan Görevler</p>
                <h3 className="text-3xl font-bold text-gray-900 mt-2">{stats.totalTasks}</h3>
              </div>
              <div className="p-3 bg-orange-50 rounded-xl">
                <CheckCircleIcon className="h-6 w-6 text-orange-600"/>
              </div>
            </div>
             <div className="mt-4 text-sm text-gray-400">
              Yapay zeka tarafından tespit edildi.
            </div>
          </div>

          {/* Kart 3: Süre */}
          <div className="bg-white p-6 rounded-2xl shadow-sm border border-gray-100 hover:shadow-md transition-shadow">
             <div className="flex justify-between items-start">
              <div>
                <p className="text-sm font-medium text-gray-400 uppercase tracking-wider">Toplam Süre</p>
                <h3 className="text-3xl font-bold text-gray-900 mt-2">{formatDuration(stats.totalDuration)}</h3>
              </div>
              <div className="p-3 bg-purple-50 rounded-xl">
                <ClockIcon className="h-6 w-6 text-purple-600"/>
              </div>
            </div>
             <div className="mt-4 text-sm text-gray-400">
              Analiz edilen ses kaydı süresi.
            </div>
          </div>
        </div>

        {/* TABLO */}
        <div className="bg-white rounded-2xl shadow-sm border border-gray-100 overflow-hidden">
          <div className="px-6 py-5 border-b border-gray-100 flex justify-between items-center bg-gray-50/50">
            <h3 className="text-lg font-bold text-gray-800">Son Toplantılar</h3>
          </div>
          
          {loading ? (
            <div className="p-12 text-center text-gray-500">Yükleniyor...</div>
          ) : (
            <div className="overflow-x-auto">
              <table className="w-full text-left border-collapse">
                <thead className="bg-gray-50 text-gray-500 text-xs uppercase font-semibold">
                  <tr>
                    <th className="px-6 py-4">Toplantı Başlığı</th>
                    <th className="px-6 py-4">Tarih</th>
                    <th className="px-6 py-4">Durum</th>
                    <th className="px-6 py-4">Görev Sayısı</th>
                    <th className="px-6 py-4 text-right">İşlem</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-gray-100">
                  {meetings.map((meeting) => (
                    <tr key={meeting.id} className="hover:bg-gray-50 transition duration-150 group">
                      <td className="px-6 py-4">
                        <div className="font-semibold text-gray-900">{meeting.title || "İsimsiz Toplantı"}</div>
                        <div className="text-xs text-gray-400 mt-0.5">ID: #{meeting.id}</div>
                      </td>
                      <td className="px-6 py-4 text-gray-600 text-sm">
                        <div className="flex items-center gap-2">
                          <CalendarIcon className="h-4 w-4 text-gray-400"/>
                          {new Date(meeting.created_at).toLocaleDateString('tr-TR', { day: 'numeric', month: 'long', year: 'numeric' })}
                        </div>
                      </td>
                      <td className="px-6 py-4">
                        <span className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium border
                          ${meeting.status === 'completed' 
                            ? 'bg-green-50 text-green-700 border-green-200' 
                            : 'bg-yellow-50 text-yellow-700 border-yellow-200'}
                        `}>
                          {meeting.status === 'completed' ? 'Analiz Tamamlandı' : 'İşleniyor...'}
                        </span>
                      </td>
                      <td className="px-6 py-4 text-sm text-gray-600 font-medium">
                        {meeting.action_items ? meeting.action_items.length : 0} Görev
                      </td>
                      <td className="px-6 py-4 text-right">
                        <button 
                          onClick={() => navigate(`/meeting/${meeting.id}`)} // <-- BU SATIR
                          className="text-indigo-600 hover:text-indigo-900 font-medium text-sm px-3 py-1.5 rounded-lg hover:bg-indigo-50 transition"
                        >
                          Detayları Gör
                        </button>
                      </td>
                    </tr>
                  ))}
                  
                  {meetings.length === 0 && (
                     <tr>
                      <td colSpan="5" className="px-6 py-12 text-center text-gray-400">
                        Henüz hiç toplantı kaydı yok.
                      </td>
                    </tr>
                  )}
                </tbody>
              </table>
            </div>
          )}
        </div>
      </main>
    </div>
  )
}

export default App