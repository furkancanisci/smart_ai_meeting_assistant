from datetime import datetime
from typing import List, Optional
from pydantic import BaseModel

class MeetingBase(BaseModel):
    title: str

class MeetingCreate(MeetingBase):
    pass

class MeetingResponse(MeetingBase):
    id: int
    status: str
    created_at: datetime
    
    class Config:
        from_attributes = True

class TranscriptSegmentResponse(BaseModel):
    speaker: str
    start: float
    text: str

class ActionItemResponse(BaseModel):
    id: int
    description: str
    assignee_name: Optional[str]
    due_date: Optional[str]
    confidence_score: float
    is_confirmed: bool
    
    class Config:
        from_attributes = True

class MeetingDetailResponse(MeetingResponse):
    transcript: List[TranscriptSegmentResponse]
    action_items: List[ActionItemResponse]
