from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from datetime import datetime, timedelta
from app.core.database import get_db
from app.api.v1.endpoints.auth import get_current_user
from app.models.domain import ActionItem, User, Meeting

router = APIRouter()

@router.get("/nudges")
async def get_proactive_nudges(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """
    Smart'ın 'Dürtme Modu'.
    Tarih format hatalarına karşı korumalı versiyon.
    """
    now = datetime.now()
    # Test için 30 günlük pencere
    warning_threshold = now + timedelta(days=30) 
    

    # 1. SQL SORGUSU
    # Not: Tarih karşılaştırmalarını (<=) burada yapmıyoruz çünkü SQLite'da tarih string olabilir.
    # Tüm pending görevleri çekip Python tarafında filtreleyeceğiz (Daha güvenli).
    query = select(ActionItem, Meeting).join(Meeting)\
        .where(
            (Meeting.owner_id == current_user.id) &
            (ActionItem.status != "completed") & 
            (ActionItem.due_date != None)
        )

    result = await db.execute(query)
    tasks = result.all()
    
    print(f"📂 Toplam Açık Görev Sayısı: {len(tasks)}")

    nudges = []
    
    for task, meeting in tasks:
        try:
            due_date_obj = None
            
            # --- TARİH DÖNÜŞTÜRME (FIX) ---
            # Veri string mi geliyor yoksa datetime objesi mi? Kontrol et.
            if isinstance(task.due_date, str):
                # String ise parse et: "2026-02-05 17:00"
                try:
                    # Saniye varsa ve yoksa diye iki formatı da dene
                    if len(task.due_date) > 16:
                        due_date_obj = datetime.strptime(task.due_date, "%Y-%m-%d %H:%M:%S")
                    else:
                        due_date_obj = datetime.strptime(task.due_date, "%Y-%m-%d %H:%M")
                except ValueError:
                    print(f"⚠️ Tarih formatı hatalı, atlanıyor: {task.due_date}")
                    continue
            elif isinstance(task.due_date, datetime):
                # Zaten datetime ise direkt al
                due_date_obj = task.due_date
            else:
                continue # Tanımsız tip
                
            # --- FİLTRELEME ---
            # Sadece 30 gün içindekileri al
            if due_date_obj > warning_threshold:
                continue
                
            # --- HESAPLAMA ---
            time_left = due_date_obj - now
            days_left = time_left.days
            hours_left = int(time_left.total_seconds() / 3600)
            
            msg = ""
            priority = "medium"

            # Mantık
            if hours_left < 0:
                # Geçmiş tarih
                msg = f"'{task.description}' görevi {abs(days_left)} gün gecikti."
                priority = "critical"
            elif days_left == 0:
                # Bugün
                msg = f"'{task.description}' görevi için son {hours_left} saat."
                priority = "high"
            elif days_left == 1:
                # Yarın
                msg = f"'{task.description}' görevi yarın."
                priority = "high"
            else:
                # İleri tarih
                msg = f"'{task.description}' görevi için {days_left} gün kaldı."
                priority = "medium"

            nudges.append({
                "id": task.id,
                "message": msg,
                "priority": priority,
                "task_title": task.description,
                "due_date": str(due_date_obj)
            })
            
        except Exception as e:
            print(f"❌ Görev İşleme Hatası (Task ID: {task.id}): {e}")
            continue

    print(f"✅ Oluşturulan Uyarı Sayısı: {len(nudges)}")
    return nudges