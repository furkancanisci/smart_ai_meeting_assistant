from fastapi import APIRouter, Depends, HTTPException, status, Form, Header
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from pydantic import BaseModel, EmailStr
from typing import Optional
from jose import JWTError, jwt

from app.core.database import get_db
from app.models.domain import User
from app.core.security import verify_password, get_password_hash, create_access_token, SECRET_KEY, ALGORITHM

# --- PYDANTIC MODELLERİ (Veri Doğrulama) ---
class UserCreate(BaseModel):
    email: EmailStr
    password: str
    full_name: str

class UserResponse(BaseModel):
    id: int
    email: str
    full_name: str
    
    class Config:
        from_attributes = True

class Token(BaseModel):
    access_token: str
    token_type: str
    user: UserResponse

# --- ROUTER ---
router = APIRouter()

# --- BAĞIMLILIKLAR (DEPENDENCIES) ---
async def get_current_user(
    authorization: str = Header(None),
    db: AsyncSession = Depends(get_db)
) -> User:
    """
    Gelen istekteki Token'ı çözer ve kullanıcıyı bulur.
    Tüm korumalı endpoint'lerde bu fonksiyonu kullanacağız.
    """
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Oturum doğrulanamadı (Geçersiz Token)",
        headers={"WWW-Authenticate": "Bearer"},
    )
    
    try:
        # Extract token from "Bearer <token>" format
        if authorization and authorization.startswith("Bearer "):
            token = authorization.split(" ")[1]
        else:
            raise credentials_exception
            
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        email: str = payload.get("sub")
        if email is None:
            raise credentials_exception
    except (JWTError, IndexError, AttributeError):
        raise credentials_exception
        
    # Kullanıcıyı veritabanında bul
    result = await db.execute(select(User).where(User.email == email))
    user = result.scalars().first()
    
    if user is None:
        raise credentials_exception
        
    return user

# --- ENDPOINTLER ---

@router.post("/register", response_model=UserResponse, status_code=201)
async def register(user_data: UserCreate, db: AsyncSession = Depends(get_db)):
    """Yeni kullanıcı kaydeder."""
    # 1. Email kontrolü
    result = await db.execute(select(User).where(User.email == user_data.email))
    existing_user = result.scalars().first()
    
    if existing_user:
        raise HTTPException(
            status_code=400,
            detail="Bu email adresi zaten kayıtlı."
        )
    
    # 2. Şifreyi Hashle ve Kaydet
    hashed_pw = get_password_hash(user_data.password)
    new_user = User(
        email=user_data.email,
        full_name=user_data.full_name,
        hashed_password=hashed_pw
    )
    
    db.add(new_user)
    await db.commit()
    await db.refresh(new_user)
    
    return new_user

@router.post("/login", response_model=Token)
async def login(
    username: str = Form(...),
    password: str = Form(...),
    db: AsyncSession = Depends(get_db)
):
    """
    Giriş yapar ve JWT Token döner.
    Not: form_data.username alanı email adresini taşır (OAuth2 standardı).
    """
    # 1. Kullanıcıyı bul
    result = await db.execute(select(User).where(User.email == username))
    user = result.scalars().first()
    
    # 2. Şifre kontrolü
    if not user or not verify_password(password, user.hashed_password):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Hatalı email veya şifre",
            headers={"WWW-Authenticate": "Bearer"},
        )
        
    # 3. Token oluştur
    access_token = create_access_token(data={"sub": user.email})
    
    return {
        "access_token": access_token, 
        "token_type": "bearer",
        "user": UserResponse(id=user.id, email=user.email, full_name=user.full_name)
    }

@router.get("/me", response_model=UserResponse)
async def read_users_me(current_user: User = Depends(get_current_user)):
    """O anki kullanıcının bilgilerini getirir (Test amaçlı)."""
    return current_user