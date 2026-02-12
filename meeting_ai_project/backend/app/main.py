from contextlib import asynccontextmanager
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from sqlalchemy import text
from app.core.database import engine, Base
# 👇 BURASI ÇOK ÖNEMLİ: teams eklendi mi?
from app.api.v1.endpoints import meetings, users, auth, teams 
import os

@asynccontextmanager
async def lifespan(app: FastAPI):
    os.makedirs("uploads", exist_ok=True)
    async with engine.begin() as conn:
        if "postgresql" in str(engine.url):
            await conn.execute(text("CREATE EXTENSION IF NOT EXISTS vector"))
        await conn.run_sync(Base.metadata.create_all)
    print("✅ Veritabanı ve Sistem Hazır!")
    yield

app = FastAPI(
    title="Smart AI Backend",
    version="2.1.0",
    lifespan=lifespan
)

# CORS
origins = ["*"]
app.add_middleware(
    CORSMiddleware,
    allow_origins=origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.mount("/uploads", StaticFiles(directory="uploads"), name="uploads")

# 👇 ROUTER TANIMLARI (BURAYI KONTROL ET)
app.include_router(auth.router, prefix="/api/v1/auth", tags=["Auth"])
app.include_router(meetings.router, prefix="/api/v1/meetings", tags=["Meetings"])
app.include_router(users.router, prefix="/api/v1/users", tags=["Users"])
app.include_router(teams.router, prefix="/api/v1/teams", tags=["Teams"]) # <-- BU SATIR EKSİKSE HATA VERİR

# ... diğer importlar
from app.api.v1.endpoints import meetings, users, auth, teams, notifications # <-- notifications eklendi

# ...
app.include_router(teams.router, prefix="/api/v1/teams", tags=["teams"])
app.include_router(notifications.router, prefix="/api/v1/notifications", tags=["notifications"]) # <-- BU SATIRI EKLE

@app.get("/")
async def root():
    return {"message": "Smart Backend Çalışıyor 🚀"}