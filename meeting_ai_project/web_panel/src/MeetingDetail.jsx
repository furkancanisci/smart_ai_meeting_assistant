import { useState, useEffect } from 'react'
import { useParams, useNavigate } from 'react-router-dom'
import axios from 'axios'
import { ArrowLeftIcon, PlayCircleIcon, CheckCircleIcon, FaceSmileIcon, ExclamationTriangleIcon } from '@heroicons/react/24/outline'

const API_URL = "http://127.0.0.1:8000/api/v1";
const BASE_URL = "http://127.0.0.1:8000"; // Ses dosyaları için

export default function MeetingDetail() {
  const { id } = useParams()
  const navigate = useNavigate()
  const [meeting, setMeeting] = useState(null)
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    const fetchDetail = async () => {
      try {
        const response = await axios.get(`${API_URL}/meetings/${id}`);
        setMeeting(response.data);
      } catch (error) {
        console.error("Detay hatası:", error);
      } finally {
        setLoading(false);
      }
    }
    fetchDetail();
  }, [id])

  if (loading) return <div className="p-10 text-center">Yükleniyor...</div>
  if (!meeting) return <div className="p-10 text-center">Toplantı bulunamadı.</div>

  // JSON verilerini güvenli parse etme
  const summary = meeting.executive_summary || {};
  const sentiment = meeting.sentiment || {};

  return (
    <div className="min-h-screen bg-gray-50 p-8 font-sans text-gray-900">
      <div className="max-w-5xl mx-auto">
        
        {/* GERİ DÖN BUTONU */}
        <button onClick={() => navigate('/')} className="flex items-center text-gray-500 hover:text-indigo-600 mb-6 transition">
          <ArrowLeftIcon className="h-5 w-5 mr-2"/>
          Listeye Dön
        </button>

        {/* BAŞLIK VE SES OYNATICI */}
        <div className="bg-white p-8 rounded-2xl shadow-sm border border-gray-100 mb-6">
          <div className="flex justify-between items-start mb-6">
            <div>
              <h1 className="text-3xl font-bold text-gray-900">{meeting.title}</h1>
              <p className="text-gray-400 mt-2">
                {new Date(meeting.created_at).toLocaleDateString('tr-TR', { day: 'numeric', month: 'long', year: 'numeric', hour: '2-digit', minute: '2-digit' })}
              </p>
            </div>
            
            {/* DUYGU DURUMU ROZETİ */}
            <div className={`px-4 py-2 rounded-xl flex items-center gap-2 border ${
              sentiment.mood?.includes('Negatif') || sentiment.mood?.includes('Gergin') 
              ? 'bg-red-50 text-red-600 border-red-100' 
              : 'bg-green-50 text-green-600 border-green-100'
            }`}>
              {sentiment.mood?.includes('Negatif') ? <ExclamationTriangleIcon className="h-6 w-6"/> : <FaceSmileIcon className="h-6 w-6"/>}
              <div className="text-right">
                <div className="text-xs uppercase font-bold opacity-70">Toplantı Havası</div>
                <div className="font-bold text-lg">{sentiment.mood || "Nötr"} ({sentiment.score || 5}/10)</div>
              </div>
            </div>
          </div>

          {/* SES OYNATICI */}
          {meeting.audio_file_path && (
             <div className="bg-gray-50 p-4 rounded-xl flex items-center gap-4">
                <div className="bg-indigo-600 p-2 rounded-full">
                   <PlayCircleIcon className="h-6 w-6 text-white"/>
                </div>
                <audio controls className="w-full h-10">
                  <source src={`${BASE_URL}/${meeting.audio_file_path}`} type="audio/wav" />
                  Tarayıcınız ses oynatmayı desteklemiyor.
                </audio>
             </div>
          )}
        </div>

        <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
          
          {/* SOL KOLON: ÖZET VE GÖREVLER */}
          <div className="lg:col-span-2 space-y-6">
            
            {/* YÖNETİCİ ÖZETİ */}
            <div className="bg-white p-6 rounded-2xl shadow-sm border border-gray-100">
              <h2 className="text-xl font-bold mb-4 flex items-center gap-2">
                <span className="w-1 h-6 bg-indigo-500 rounded-full"></span>
                Yönetici Özeti
              </h2>
              
              <div className="space-y-4">
                {summary.decisions && (
                  <div>
                    <h3 className="font-semibold text-gray-700 mb-2">📌 Alınan Kararlar</h3>
                    <ul className="list-disc list-inside text-gray-600 space-y-1 ml-2">
                      {summary.decisions.map((item, i) => <li key={i}>{item}</li>)}
                    </ul>
                  </div>
                )}
                
                {summary.action_plan && (
                  <div>
                    <h3 className="font-semibold text-gray-700 mb-2">🚀 Aksiyon Planı</h3>
                    <ul className="list-disc list-inside text-gray-600 space-y-1 ml-2">
                      {summary.action_plan.map((item, i) => <li key={i}>{item}</li>)}
                    </ul>
                  </div>
                )}
              </div>
            </div>

            {/* GÖREV LİSTESİ */}
            <div className="bg-white p-6 rounded-2xl shadow-sm border border-gray-100">
              <h2 className="text-xl font-bold mb-4 flex items-center gap-2">
                <span className="w-1 h-6 bg-orange-500 rounded-full"></span>
                Görevler ({meeting.action_items?.length || 0})
              </h2>
              <div className="space-y-3">
                {meeting.action_items?.map((task) => (
                  <div key={task.id} className="flex items-start gap-3 p-4 bg-gray-50 rounded-xl border border-gray-100 hover:bg-white hover:shadow-md transition">
                    <CheckCircleIcon className="h-6 w-6 text-orange-500 mt-0.5 flex-shrink-0"/>
                    <div>
                      <p className="font-semibold text-gray-800">{task.description}</p>
                      <div className="flex gap-4 mt-2 text-sm">
                        <span className="text-indigo-600 bg-indigo-50 px-2 py-0.5 rounded">👤 {task.assignee_name || "Belirsiz"}</span>
                        {task.due_date && <span className="text-red-500 bg-red-50 px-2 py-0.5 rounded">📅 {task.due_date}</span>}
                      </div>
                    </div>
                  </div>
                ))}
                {(!meeting.action_items || meeting.action_items.length === 0) && <p className="text-gray-400">Görev bulunamadı.</p>}
              </div>
            </div>

          </div>

          {/* SAĞ KOLON: TRANSKRİPT (DÖKÜM) */}
          <div className="bg-white p-6 rounded-2xl shadow-sm border border-gray-100 h-[800px] overflow-y-auto">
             <h2 className="text-xl font-bold mb-4 sticky top-0 bg-white pb-2 border-b border-gray-100">
               Konuşma Dökümü
             </h2>
             <div className="space-y-4">
               {meeting.transcript?.map((seg) => (
                 <div key={seg.id} className={`p-3 rounded-lg text-sm ${seg.speaker_label === 'Misafir' ? 'bg-gray-50' : 'bg-indigo-50'}`}>
                    <div className="font-bold text-xs mb-1 opacity-70 flex justify-between">
                      <span>{seg.speaker_label}</span>
                      <span>{Math.floor(seg.start_time)}s</span>
                    </div>
                    <p className="text-gray-700 leading-relaxed">{seg.text}</p>
                 </div>
               ))}
             </div>
          </div>

        </div>
      </div>
    </div>
  )
}