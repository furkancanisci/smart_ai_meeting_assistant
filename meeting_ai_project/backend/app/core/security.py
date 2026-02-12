from datetime import datetime, timedelta
from typing import Optional, Union
from jose import jwt
from passlib.context import CryptContext
import os

# --- AYARLAR ---
# Gerçek projede bunları .env dosyasından çekmeliyiz.
# Şimdilik burada sabitliyoruz.
SECRET_KEY = os.getenv("SECRET_KEY", "smart_ai_super_gizli_anahtar_2026")
ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = 60 * 24 * 7  # 1 Hafta boyunca oturum açık kalsın

# Şifre Hashleme Bağlamı
pwd_context = CryptContext(schemes=["argon2"], deprecated="auto")

def verify_password(plain_password: str, hashed_password: str) -> bool:
    """Girilen şifre ile veritabanındaki hash'i karşılaştırır."""
    return pwd_context.verify(plain_password, hashed_password)

def get_password_hash(password: str) -> str:
    """Şifreyi veritabanına kaydetmeden önce hash'ler."""
    return pwd_context.hash(password)

def create_access_token(data: dict, expires_delta: Optional[timedelta] = None) -> str:
    """Kullanıcı için JWT Token oluşturur."""
    to_encode = data.copy()
    
    if expires_delta:
        expire = datetime.utcnow() + expires_delta
    else:
        expire = datetime.utcnow() + timedelta(minutes=15)
        
    to_encode.update({"exp": expire})
    
    encoded_jwt = jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)
    return encoded_jwt