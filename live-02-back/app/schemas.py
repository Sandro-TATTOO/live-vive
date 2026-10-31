from pydantic import BaseModel
from typing import Optional
from datetime import datetime

class TokenRequest(BaseModel):
    room: str
    identity: Optional[str] = "user"

class TokenResponse(BaseModel):
    server_url: str
    token: str
    room: str
    identity: str
    expires_in: int

class ViewerJoin(BaseModel):
    stream_id: str
    user_id: str

class ViewerStats(BaseModel):
    viewer_count: int

from enum import Enum

class MessageType(str, Enum):
    chat = "chat"
    gift = "gift"
    system = "system"
    vip = "vip"


class MessageCreate(BaseModel):
    stream_id: str
    user_id: str
    message_type: MessageType
    content: str

class SupabaseLogin(BaseModel):
    access_token: str

class UserCreate(BaseModel):
    username: str
    email: str
    password: str

class Message(BaseModel):
    id: str
    stream_id: str
    user_id: str
    message_type: MessageType
    content: str
    created_at: datetime
    is_deleted: bool = False

class User(BaseModel):
    username: str
    email: str




