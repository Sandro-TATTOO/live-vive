from app.db.supabase_client import get_global_supabase
from typing import List
from datetime import datetime, timedelta
from collections import defaultdict
import time

from enum import Enum

class MessageType(str, Enum):
    chat = "chat"
    gift = "gift"
    system = "system"
    vip = "vip"


from pydantic import BaseModel
from collections import defaultdict

# Rate limit simples (in-memory, 3 msg/min por user)
_rate_limits = defaultdict(list)





class MessageCreate(BaseModel):
    stream_id: str
    user_id: str
    message_type: MessageType
    content: str

class Message(BaseModel):
    id: str
    stream_id: str
    user_id: str
    message_type: MessageType
    content: str
    created_at: datetime
    is_deleted: bool = False

def send_message(msg: MessageCreate) -> Message:
    """POST message com rate limit"""
    now = time.time()
    
    # Rate limit 3/min por user+stream
    user_key = f"{msg.user_id}:{msg.stream_id}"
    user_times = _rate_limits[user_key]
    user_times = [t for t in user_times if now - t < 60]  # 1min window
    if len(user_times) >= 3:
        raise ValueError("Rate limit: max 3 msg/min")
    user_times.append(now)
    _rate_limits[user_key] = user_times
    
    supabase = get_global_supabase()
    if not supabase:
        raise ValueError("Supabase not configured")
    
    # Validar stream ativo (opcional)
    stream = supabase.table('streams').select('status').eq('id', msg.stream_id).single().execute()
    if not stream.data or stream.data['status'] != 'live':
        raise ValueError("Stream not live")
    
    # Insert
    data = msg.dict()
    result = supabase.table('stream_messages').insert(data).execute()
    
    if result.data:
        msg_db = result.data[0]
        return Message(**msg_db)
    raise ValueError("Failed to save message")

def get_messages(stream_id: str, limit: int = 50, offset: int = 0) -> List[Message]:
    """GET messages paginadas DESC created_at"""
    supabase = get_global_supabase()
    if not supabase:
        return []
    
    result = supabase.table('stream_messages')\
        .select('*')\
        .eq('stream_id', stream_id)\
        .eq('is_deleted', False)\
        .order('created_at', desc=True)\
        .range(offset, offset + limit - 1)\
        .execute()
    
    return [Message(**m) for m in result.data]

def delete_message(message_id: str, user_id: str) -> bool:
    """Soft delete (own or mod)"""
    supabase = get_global_supabase()
    if not supabase:
        return False
    
    result = supabase.table('stream_messages')\
        .update({'is_deleted': True})\
        .eq('id', message_id)\
        .eq('user_id', user_id)\
        .execute()
    
    return bool(result.count > 0)


