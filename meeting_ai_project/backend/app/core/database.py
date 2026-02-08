from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession, async_sessionmaker
from sqlalchemy.orm import declarative_base

# Veritabanı URL'si (Seninkine göre ayarlı)
DATABASE_URL = "sqlite+aiosqlite:///./meeting_ai.db"

engine = create_async_engine(DATABASE_URL, echo=True)

# BU SATIR ÇOK ÖNEMLİ:
AsyncSessionLocal = async_sessionmaker(
    bind=engine,
    class_=AsyncSession,
    expire_on_commit=False,
    autoflush=False
)

Base = declarative_base()

# Dependency (Bunu zaten kullanıyorduk)
async def get_db():
    async with AsyncSessionLocal() as session:
        yield session