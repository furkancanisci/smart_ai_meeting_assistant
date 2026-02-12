from fastapi import APIRouter, Depends, UploadFile, File, BackgroundTasks, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, or_
from sqlalchemy.orm import selectinload
from app.core.database import get_db, AsyncSessionLocal
from app.models.domain import Meeting, MeetingStatus, TranscriptSegment, ActionItem, VoiceProfile, User
from app.services.audio_service import audio_service
from app.services.llm_service import llm_service
from app.services.voice_service import voice_service
from app.services.rag_service import rag_service # <-- RAG Servisi Eklendi
from app.api.v1.endpoints.auth import get_current_user # <-- Auth Eklendi
from pydub import AudioSegment 
from pydantic import BaseModel 
import shutil
import os
import soundfile as sf
import numpy as np
import json
from datetime import datetime

router = APIRouter()

# Chat istekleri için model
class ChatRequest(BaseModel):
    query: str

# --- GÖREVLER ENDPOINTİ (Auth Destekli) ---
@router.get("/tasks/all")
async def get_all_tasks(
    current_user: User = Depends(get_current_user), # <-- Sadece giriş yapanın görevleri
    db: AsyncSession = Depends(get_db)
):
    """
    Kullanıcının tüm toplantılarından çıkarılan görevleri getirir.
    """
    # Kullanıcıya ait toplantıları ve onların görevlerini birleştir
    query = select(ActionItem, Meeting).join(Meeting)\
        .where(Meeting.owner_id == current_user.id)\
        .order_by(ActionItem.due_date.asc().nulls_last())
        
    result = await db.execute(query)
    
    tasks_with_context = []
    for task, meeting in result.all():
        tasks_with_context.append({
            "id": task.id,
            "description": task.description,
            "assignee": task.assignee_name,
            "due_date": task.due_date,
            "confidence": task.confidence_score,
            "meeting_id": meeting.id,
            "meeting_title": meeting.title,
            "created_at": meeting.created_at
        })
        
    return tasks_with_context

@router.post("/upload", status_code=201)
async def upload_meeting(
    background_tasks: BackgroundTasks,
    file: UploadFile = File(...),
    title: str = "Adsız Toplantı",
    current_user: User = Depends(get_current_user), # <-- Auth Eklendi
    db: AsyncSession = Depends(get_db)
):
    upload_dir = "uploads"
    os.makedirs(upload_dir, exist_ok=True)
    
    # Dosya ismini güvenli hale getir (Kullanıcı ID'si ile başlasın)
    safe_filename = f"user_{current_user.id}_{file.filename.replace(' ', '_')}"
    file_path = os.path.join(upload_dir, safe_filename)
    
    with open(file_path, "wb") as buffer:
        shutil.copyfileobj(file.file, buffer)
        
    new_meeting = Meeting(
        owner_id=current_user.id, # <-- Dinamik User ID
        title=title,
        audio_file_path=file_path,
        status=MeetingStatus.UPLOADING
    )
    db.add(new_meeting)
    await db.commit()
    await db.refresh(new_meeting)
    
    background_tasks.add_task(process_meeting_task, new_meeting.id, file_path)
    
    return {"id": new_meeting.id, "message": "Yüklendi, analiz başlıyor..."}

async def process_meeting_task(meeting_id: int, file_path: str):
    print(f"🚀 Meeting ID {meeting_id} için analiz başladı...")
    
    async with AsyncSessionLocal() as db:
        try:
            # 1. Durumu Güncelle -> PROCESSING
            meeting = await db.get(Meeting, meeting_id)
            if not meeting: return
            meeting.status = MeetingStatus.PROCESSING
            await db.commit()

            # --- FORMAT DÖNÜŞTÜRME (m4a -> wav) ---
            if not file_path.lower().endswith(".wav"):
                print(f"🔄 Format Dönüştürülüyor: {file_path} -> WAV")
                try:
                    audio = AudioSegment.from_file(file_path)
                    wav_path = os.path.splitext(file_path)[0] + ".wav"
                    audio.export(wav_path, format="wav")
                    
                    file_path = wav_path 
                    meeting.audio_file_path = wav_path
                    await db.commit()
                    print("✅ Dönüştürme Başarılı!")
                except Exception as e:
                    print(f"⚠️ Format dönüştürme hatası: {e}")
            # --------------------------------------

            # 2. Transkripsiyon
            result = audio_service.transcribe(file_path)
            segments = result.get("segments", [])
            
            # 3. Ses Profillerini Hazırla
            profiles_result = await db.execute(select(VoiceProfile, User).join(User))
            known_profiles = []
            for vp, user in profiles_result:
                try:
                    embedding_data = vp.embedding
                    if isinstance(embedding_data, str):
                        embedding_data = json.loads(embedding_data)
                    known_profiles.append({"name": user.full_name, "embedding": embedding_data})
                except: pass

            # 4. Ses Dosyasını Oku ve Tanıma Yap
            full_audio_data, sample_rate = sf.read(file_path)
            if len(full_audio_data.shape) > 1:
                full_audio_data = np.mean(full_audio_data, axis=1)

            full_text_list = []

            for seg in segments:
                start_sec = seg["start"]
                end_sec = seg["end"]
                raw_text = seg["text"].strip()
                speaker_name = "Misafir"
                
                # A) Metin Düzeltme
                if len(raw_text) > 5:
                    text = await llm_service.correct_transcript(raw_text)
                else:
                    text = raw_text

                # B) Ses Tanıma
                start_frame = int(start_sec * sample_rate)
                end_frame = int(end_sec * sample_rate)
                if end_frame - start_frame > sample_rate * 0.5:
                    segment_audio = full_audio_data[start_frame:end_frame]
                    seg_path = f"temp_seg_{meeting_id}_{int(start_sec)}.wav"
                    sf.write(seg_path, segment_audio, sample_rate)
                    try:
                        vec = voice_service.extract_embedding(seg_path)
                        name, score = voice_service.identify_speaker(vec, known_profiles)
                        if score > 0.35: speaker_name = name
                    except: pass
                    finally:
                        if os.path.exists(seg_path): os.remove(seg_path)

                full_text_list.append(f"{speaker_name}: {text}")
                
                new_segment = TranscriptSegment(
                    meeting_id=meeting_id,
                    start_time=start_sec,
                    end_time=end_sec,
                    speaker_label=speaker_name,
                    text=text
                )
                db.add(new_segment)
            
            await db.commit()

            # --- ANALİZ AŞAMASI ---
            full_transcript_str = "\n".join(full_text_list)
            
            if len(full_transcript_str) > 10:
                # 1. ÖZET & DUYGU
                exec_summary_json = await llm_service.generate_executive_summary(full_transcript_str)
                meeting.executive_summary = json.dumps(exec_summary_json, ensure_ascii=False)
                
                sentiment_json = await llm_service.analyze_sentiment(full_transcript_str)
                meeting.sentiment = json.dumps(sentiment_json, ensure_ascii=False)
                await db.commit()

                # 2. GÖREVLER
                extracted_tasks = await llm_service.extract_action_items(full_transcript_str)
                for task in extracted_tasks:
                    new_item = ActionItem(
                        meeting_id=meeting_id,
                        description=task.get("description", "Tanımsız"),
                        assignee_name=task.get("assignee", "Belirsiz"),
                        due_date=task.get("due_date"),
                        confidence_score=task.get("confidence", 0.0)
                    )
                    db.add(new_item)
                await db.commit()

                # --- 3. KURUM HAFIZASINA KAYDET (RAG) ---
                print("🧠 Kurum Hafızasına (Vector DB) Kaydediliyor...")
                # DB'den temiz segmentleri çek
                saved_segments = await db.execute(select(TranscriptSegment).where(TranscriptSegment.meeting_id == meeting_id))
                segments_list = [{"speaker_label": s.speaker_label, "text": s.text, "start_time": s.start_time} for s in saved_segments.scalars().all()]
                
                # RAG Servisine gönder
                rag_service.add_meeting_to_memory(meeting_id, segments_list, meeting.title)
                # ----------------------------------------

            final_meeting = await db.get(Meeting, meeting_id)
            final_meeting.status = MeetingStatus.COMPLETED
            await db.commit()
            print(f"✅ TÜM ANALİZLER BAŞARIYLA TAMAMLANDI: Meeting {meeting_id}")

        except Exception as e:
            print(f"❌ Arka Plan Görevi Hatası: {e}")
            try:
                err_meeting = await db.get(Meeting, meeting_id)
                if err_meeting:
                    err_meeting.status = MeetingStatus.FAILED
                    await db.commit()
            except:
                pass

@router.get("/{meeting_id}")
async def get_meeting_details(
    meeting_id: int, 
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    query = select(Meeting).where(Meeting.id == meeting_id)
    result = await db.execute(query)
    meeting = result.scalars().first()
    
    if not meeting:
        raise HTTPException(status_code=404, detail="Toplantı bulunamadı")
        
    # Güvenlik kontrolü: Başkasının toplantısını göremesin (Şimdilik takım yoksa)
    if meeting.owner_id != current_user.id and meeting.team_id is None:
        # İleride takım kontrolü de buraya eklenecek
        pass 
    
    segments = await db.execute(select(TranscriptSegment).where(TranscriptSegment.meeting_id == meeting_id))
    actions = await db.execute(select(ActionItem).where(ActionItem.meeting_id == meeting_id))
    
    exec_summary = {}
    if meeting.executive_summary:
        try: exec_summary = json.loads(meeting.executive_summary)
        except: pass

    sentiment = {}
    if meeting.sentiment:
        try: sentiment = json.loads(meeting.sentiment)
        except: pass

    return {
        "id": meeting.id,
        "title": meeting.title,
        "status": meeting.status,
        "created_at": meeting.created_at,
        "transcript": [s.__dict__ for s in segments.scalars().all()],
        "action_items": [a.__dict__ for a in actions.scalars().all()],
        "executive_summary": exec_summary,
        "sentiment": sentiment
    }

@router.get("/")
async def list_meetings(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """
    Sadece kullanıcının kendi toplantılarını listeler.
    """
    query = select(Meeting).where(Meeting.owner_id == current_user.id)\
        .options(selectinload(Meeting.action_items))\
        .order_by(Meeting.id.desc())
        
    result = await db.execute(query)
    return result.scalars().all()

@router.post("/{meeting_id}/chat")
async def chat_with_meeting_bot(
    meeting_id: int, 
    request: ChatRequest, 
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    # Toplantıyı çek
    query = select(Meeting).where(Meeting.id == meeting_id)
    result = await db.execute(query)
    meeting = result.scalars().first()
    
    if not meeting:
        raise HTTPException(status_code=404, detail="Toplantı bulunamadı")

    # Transkripti oluştur
    segments_result = await db.execute(select(TranscriptSegment).where(TranscriptSegment.meeting_id == meeting_id))
    segments = segments_result.scalars().all()
    
    full_transcript = "\n".join([f"{s.speaker_label}: {s.text}" for s in segments])
    
    if not full_transcript:
        return {"answer": "Bu toplantının henüz bir dökümü yok."}

    answer = await llm_service.chat_with_context(full_transcript, request.query)
    return {"answer": answer}

# --- GLOBAL CHAT (GÜNCELLENMİŞ HİBRİT VERSİYON) ---
@router.post("/global-chat")
async def global_chat(
    request: ChatRequest, 
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """
    Hem Vektör Arama (Metin) hem de Veritabanı Sorgusu (Görevler) yaparak en doğru cevabı üretir.
    """
    print(f"🧠 AI Arama Yapılıyor: {request.query}")
    
    # 1. RAG ARAMASI (Metinlerde Ara)
    relevant_contexts = rag_service.search_memory(request.query, limit=15)
    context_str = "\n".join(relevant_contexts) if relevant_contexts else ""

    # 2. GÖREV LİSTESİ (Kopya Kağıdı)
    # Son 10 aktif görevi çekip bağlama ekleyelim. Böylece tarih sorularını kaçırmaz.
    tasks_query = select(ActionItem, Meeting).join(Meeting)\
        .where(Meeting.owner_id == current_user.id)\
        .order_by(ActionItem.due_date.desc())\
        .limit(10)
    
    tasks_result = await db.execute(tasks_query)
    tasks_list = tasks_result.all()
    
    tasks_context = ""
    if tasks_list:
        tasks_context = "\n--- ÇIKARILAN GÖREVLER VE TARİHLER ---\n"
        for task, meeting in tasks_list:
            due = task.due_date if task.due_date else "Tarih Yok"
            assignee = task.assignee_name if task.assignee_name else "Belirsiz"
            tasks_context += f"- Görev: {task.description} | Tarih: {due} | Sorumlu: {assignee} (Toplantı: {meeting.title})\n"

    # Hiçbir şey bulunamazsa
    if not context_str and not tasks_context:
        return {"answer": "Kayıtlarımda bu konuyla ilgili net bir bilgi bulamadım."}

    # 3. LLM'e HEPSİNİ GÖNDER
    current_date = datetime.now().strftime("%d.%m.%Y")
    current_day = datetime.now().strftime("%A")
    
    full_prompt_context = f"""
    Sen, 'Smart' adında profesyonel bir toplantı asistanısın.
    Aşağıda, geçmiş toplantı notları ve veritabanından çekilen görev listesi var.
    
    GÖREV LİSTESİ, kesin tarihleri içerir. Eğer kullanıcı tarih veya 'ne zaman' sorusu sorarsa ÖNCELİKLE görev listesine bak.
    Metin notları ise detayı içerir.
    
    --- MEVCUT TARİH BİLGİSİ ---
    Bugünün Tarihi: {current_date}
    Gün: {current_day}
    
    --- GÖREV VE TARİH LİSTESİ (KESİN BİLGİ) ---
    {tasks_context}
    
    --- TOPLANTI KONUŞMA NOTLARI (DETAYLAR) ---
    {context_str}
    ------------------------
    
    Soru: {request.query}
    Cevap (Net ve kısa konuş):
    """
    
    answer = await llm_service.chat_with_context(full_prompt_context, request.query)
    
    return {"answer": answer}