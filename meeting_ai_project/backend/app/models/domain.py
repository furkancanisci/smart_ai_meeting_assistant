from sqlalchemy import Column, Integer, String, Float, ForeignKey, DateTime, Boolean, Text, Table
from sqlalchemy.orm import relationship, Mapped, mapped_column
from sqlalchemy.sql import func
from app.core.database import Base
import enum
from typing import List, Optional

# --- ENUM ---
class MeetingStatus(str, enum.Enum):
    UPLOADING = "uploading"
    PROCESSING = "processing"
    COMPLETED = "completed"
    FAILED = "failed"

# --- MODELLER ---

# Çoka-Çok İlişki Tablosu (Takım Üyeleri)
# Hangi kullanıcı hangi takımda?
class TeamMember(Base):
    __tablename__ = "team_members"
    
    team_id = Column(Integer, ForeignKey("teams.id"), primary_key=True)
    user_id = Column(Integer, ForeignKey("users.id"), primary_key=True)
    role = Column(String, default="member") # 'admin', 'member'
    joined_at = Column(DateTime(timezone=True), server_default=func.now())

class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    email = Column(String, unique=True, index=True)
    full_name = Column(String)
    hashed_password = Column(String)
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    # İlişkiler
    voice_profile = relationship("VoiceProfile", back_populates="user", uselist=False)
    meetings = relationship("Meeting", back_populates="owner")
    
    # Kullanıcının dahil olduğu takımlar
    teams = relationship("Team", secondary="team_members", back_populates="members")

class Team(Base):
    __tablename__ = "teams"
    
    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, index=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    owner_id = Column(Integer, ForeignKey("users.id")) # Takımı kuran kişi
    
    # İlişkiler
    members = relationship("User", secondary="team_members", back_populates="teams")
    meetings = relationship("Meeting", back_populates="team")

class Meeting(Base):
    __tablename__ = "meetings"

    id = Column(Integer, primary_key=True, index=True)
    owner_id = Column(Integer, ForeignKey("users.id")) # Toplantıyı yükleyen
    team_id = Column(Integer, ForeignKey("teams.id"), nullable=True) # Hangi takıma ait? (Opsiyonel)
    
    title = Column(String, index=True)
    audio_file_path = Column(String)
    duration_seconds = Column(Float, nullable=True)
    status = Column(String, default=MeetingStatus.UPLOADING)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    
    # AI Analiz Sonuçları (JSON String olarak saklanır)
    executive_summary = Column(Text, nullable=True) # Yönetici Özeti
    sentiment = Column(Text, nullable=True)         # Duygu Analizi
    
    # İlişkiler
    owner = relationship("User", back_populates="meetings")
    team = relationship("Team", back_populates="meetings")
    segments = relationship("TranscriptSegment", back_populates="meeting", cascade="all, delete-orphan")
    action_items = relationship("ActionItem", back_populates="meeting", cascade="all, delete-orphan")

class TranscriptSegment(Base):
    __tablename__ = "transcript_segments"

    id = Column(Integer, primary_key=True, index=True)
    meeting_id = Column(Integer, ForeignKey("meetings.id"))
    
    start_time = Column(Float)
    end_time = Column(Float)
    speaker_label = Column(String) # Örn: "Speaker 1" veya "Ahmet Yılmaz"
    text = Column(String)
    
    meeting = relationship("Meeting", back_populates="segments")

class ActionItem(Base):
    __tablename__ = "action_items"

    id = Column(Integer, primary_key=True, index=True)
    meeting_id = Column(Integer, ForeignKey("meetings.id"))
    
    description = Column(String)
    assignee_name = Column(String, nullable=True) # Atanan kişi
    due_date = Column(String, nullable=True)      # Son tarih (YYYY-MM-DD)
    status = Column(String, default="pending")    # pending, completed
    confidence_score = Column(Float, default=0.0) 
    
    meeting = relationship("Meeting", back_populates="action_items")

class VoiceProfile(Base):
    __tablename__ = "voice_profiles"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), unique=True)
    embedding = Column(Text) # Vektör verisi (JSON string)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    
    user = relationship("User", back_populates="voice_profile")