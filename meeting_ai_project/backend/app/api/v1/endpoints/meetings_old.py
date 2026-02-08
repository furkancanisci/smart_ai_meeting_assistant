import os
import shutil
from typing import Any
from fastapi import APIRouter, Depends, UploadFile, File, HTTPException, Form
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select

from app.core.database import get_db
from app.core.config import settings
from app.models.domain import Meeting, User, MeetingStatus

router = APIRouter()

# --- GEÇİCİ YARDIMCI FONKSİYON ---
# Auth sistemi kurana kadar, veritabanındaki ilk kullanıcıyı "aktif kullanıcı" sayacağız.
async def get_current_user_mock(db: AsyncSession = Depends(get_db)) -> User:
    result = await db.execute(select(User).limit(1))
    user = result.scalars().first()
    if not user:
        # Eğer hiç kullanıcı yoksa test için bir tane oluşturalım
        new_user = User(email="test@demo.com", hashed_password="fake", full_name="Test Kullanıcı")
        db.add(new_user)
        await db.commit()
        await db.refresh(new_user)
        return new_user
    return user

@router.post("/upload", status_code=201)
async def upload_meeting(
    *,
    db: AsyncSession = Depends(get_db),
    file: UploadFile = File(...),
    title: str = Form("İsimsiz Toplantı"), # Flutter'dan form-data olarak gelecek
    current_user: User = Depends(get_current_user_mock)
) -> Any:
    """
    Ses dosyasını yükler ve işleme kuyruğuna alır (şimdilik sadece DB'ye yazar).
    """
    
    # 1. Dosya Kontrolü (Basitçe uzantıya bakalım)
    if not file.filename.endswith(('.wav', '.mp3', '.m4a', '.mp4')):
        raise HTTPException(status_code=400, detail="Desteklenmeyen dosya formatı.")

    # 2. Dosya ismini benzersiz yap (çakışmayı önlemek için ID veya Timestamp eklenebilir)
    # Şimdilik basit tutalım: meeting_{user_id}_{filename}
    safe_filename = f"user_{current_user.id}_{file.filename}"
    file_path = os.path.join(settings.UPLOAD_DIR, safe_filename)

    # 3. Dosyayı Diske Kaydet
    try:
        with open(file_path, "wb") as buffer:
            shutil.copyfileobj(file.file, buffer)
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Dosya kaydedilemedi: {str(e)}")

    # 4. Veritabanı Kaydı Oluştur
    new_meeting = Meeting(
        owner_id=current_user.id,
        title=title,
        audio_file_path=file_path,
        status=MeetingStatus.UPLOADING # Önce uploading, sonra processing olacak
    )
    
    db.add(new_meeting)
    await db.commit()
    await db.refresh(new_meeting)

    return {
        "id": new_meeting.id,
        "title": new_meeting.title,
        "status": new_meeting.status,
        "message": "Dosya başarıyla yüklendi, analiz için hazır."
    }

@router.get("/", response_model=list)
async def get_my_meetings(
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user_mock)
):
    """Kullanıcının geçmiş toplantılarını listeler"""
    result = await db.execute(select(Meeting).where(Meeting.owner_id == current_user.id))
    meetings = result.scalars().all()
    return meetings
