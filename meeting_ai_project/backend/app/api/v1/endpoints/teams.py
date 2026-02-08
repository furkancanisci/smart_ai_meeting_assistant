from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from pydantic import BaseModel
from typing import List

from app.core.database import get_db
from app.models.domain import Team, User, TeamMember
from app.api.v1.endpoints.auth import get_current_user

router = APIRouter()

# --- MODELLER ---
class TeamCreate(BaseModel):
    name: str

class TeamMemberAdd(BaseModel):
    email: str

class TeamResponse(BaseModel):
    id: int
    name: str
    owner_id: int
    member_count: int = 0

# --- ENDPOINTLER ---

@router.post("/", response_model=TeamResponse)
async def create_team(
    team_data: TeamCreate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Yeni bir takım oluşturur."""
    new_team = Team(name=team_data.name, owner_id=current_user.id)
    db.add(new_team)
    await db.commit()
    await db.refresh(new_team)
    
    # Kurucuyu otomatik üye yap (Admin rolüyle)
    member = TeamMember(team_id=new_team.id, user_id=current_user.id, role="admin")
    db.add(member)
    await db.commit()
    
    return {
        "id": new_team.id,
        "name": new_team.name,
        "owner_id": new_team.owner_id,
        "member_count": 1
    }

@router.get("/", response_model=List[TeamResponse])
async def get_my_teams(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Kullanıcının üye olduğu takımları listeler."""
    # current_user.teams ilişkisi lazy load olduğu için explicit sorgu atalım
    query = select(Team).join(TeamMember).where(TeamMember.user_id == current_user.id)
    result = await db.execute(query)
    teams = result.scalars().all()
    
    # Üye sayılarını hesaplamak için basit bir döngü (MVP için)
    # Performans için ileride count query kullanılır.
    response_data = []
    for team in teams:
        member_count_q = select(TeamMember).where(TeamMember.team_id == team.id)
        res = await db.execute(member_count_q)
        count = len(res.scalars().all())
        
        response_data.append({
            "id": team.id,
            "name": team.name,
            "owner_id": team.owner_id,
            "member_count": count
        })
        
    return response_data

@router.post("/{team_id}/members")
async def add_member(
    team_id: int,
    member_data: TeamMemberAdd,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Takıma email ile üye ekler."""
    # 1. Takımı bul ve yetki kontrolü (Sadece üyeler ekleyebilsin - şimdilik basit)
    team_query = select(Team).join(TeamMember).where(
        (Team.id == team_id) & (TeamMember.user_id == current_user.id)
    )
    result = await db.execute(team_query)
    team = result.scalars().first()
    
    if not team:
        raise HTTPException(status_code=404, detail="Takım bulunamadı veya yetkiniz yok.")
        
    # 2. Eklenecek kullanıcıyı bul
    user_query = select(User).where(User.email == member_data.email)
    user_result = await db.execute(user_query)
    new_member_user = user_result.scalars().first()
    
    if not new_member_user:
        raise HTTPException(status_code=404, detail="Kullanıcı bulunamadı (Email kayıtlı değil).")
        
    # 3. Zaten üye mi?
    check_query = select(TeamMember).where(
        (TeamMember.team_id == team_id) & (TeamMember.user_id == new_member_user.id)
    )
    check_result = await db.execute(check_query)
    if check_result.scalars().first():
        return {"message": "Kullanıcı zaten takımda."}
        
    # 4. Ekle
    new_member = TeamMember(team_id=team_id, user_id=new_member_user.id, role="member")
    db.add(new_member)
    await db.commit()
    
    return {"message": f"{new_member_user.full_name} takıma eklendi."}