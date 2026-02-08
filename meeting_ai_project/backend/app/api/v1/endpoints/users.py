from fastapi import APIRouter, Depends, UploadFile, File, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from app.core.database import get_db
from app.models.domain import User, VoiceProfile
from app.services.voice_service import voice_service
import shutil
import os
import json  # <--- EKLENDİ: Listeyi String'e çevirmek için şart

router = APIRouter()

@router.post("/enroll_voice")
async def enroll_voice(
    file: UploadFile = File(...),
    db: AsyncSession = Depends(get_db)
):
    # 1. Kullanıcıyı Bul (Şimdilik ID=1 sabit)
    user_id = 1
    user = await db.get(User, user_id)
    if not user:
        raise HTTPException(status_code=404, detail="Kullanıcı bulunamadı")

    # 2. Dosyayı Kaydet
    upload_dir = "uploads/voice_samples"
    os.makedirs(upload_dir, exist_ok=True)
    file_path = os.path.join(upload_dir, f"enroll_{user_id}.wav")
    
    with open(file_path, "wb") as buffer:
        shutil.copyfileobj(file.file, buffer)

    # 3. Vektör Çıkar
    try:
        vector = voice_service.extract_embedding(file_path)
        
        # Eğer vektör boş veya hatalıysa dur
        if not vector or len(vector) != 192:
            raise HTTPException(status_code=400, detail="Ses analiz edilemedi, lütfen tekrar deneyin.")

        # 4. Veritabanına Kaydet/Güncelle
        # Önce var mı diye bak
        result = await db.execute(select(VoiceProfile).where(VoiceProfile.user_id == user_id))
        voice_profile = result.scalars().first()

        # DÜZELTME BURADA YAPILDI: Listeyi JSON String'e çeviriyoruz
        vector_json = json.dumps(vector)

        if voice_profile:
            # Güncelle
            voice_profile.embedding = vector_json
            voice_profile.sample_count += 1
        else:
            # Yeni Oluştur
            voice_profile = VoiceProfile(
                user_id=user_id,
                embedding=vector_json,
                sample_count=1
            )
            db.add(voice_profile)
        
        await db.commit()
        
        # Geçici dosyayı temizle
        if os.path.exists(file_path):
            os.remove(file_path)

        return {"message": "Ses profiliniz başarıyla oluşturuldu! Artık sizi tanıyabilirim."}

    except Exception as e:
        print(f"Hata detayı: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/{user_id}")
async def read_user(user_id: int, db: AsyncSession = Depends(get_db)):
    user = await db.get(User, user_id)
    if user is None:
        raise HTTPException(status_code=404, detail="User not found")
    return user