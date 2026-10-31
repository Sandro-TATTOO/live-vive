from fastapi import APIRouter, HTTPException, Query
from pydantic import BaseModel
from datetime import datetime
import uuid

from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from datetime import datetime
import uuid

from app.services.livekit_service import create_livekit_token
from app.services.viewer_service import join_stream, leave_stream, get_viewer_count, ViewerStats, ViewerJoin
from app.services.chat_service import send_message, get_messages, MessageCreate, Message
from app.db.supabase_client import get_global_supabase
from app.config import settings

router = APIRouter()

# =========================
# MODELO START STREAM
# =========================
class StartStreamRequest(BaseModel):
    title: str
    host_id: str


# =========================
# 1. LISTAR LIVES ATIVAS
# =========================
@router.get("/streams/live")
def get_live_streams():
    supabase = get_global_supabase()

    response = supabase.table("streams") \
        .select("*") \
        .eq("status", "live") \
        .execute()

    return response.data


# =========================
# 2. START STREAM (HOST)
# =========================
@router.post("/streams/start")
def start_stream(payload: StartStreamRequest):
    supabase = get_global_supabase()

    stream_id = str(uuid.uuid4())

    data = {
        "id": stream_id,
        "host_id": payload.host_id,
        "title": payload.title,
        "status": "live",
        "viewer_count": 0,
        "started_at": datetime.utcnow().isoformat(),
    }

    response = supabase.table("streams").insert(data).execute()

    return {
        "stream_id": stream_id,
        "status": "live",
        "data": response.data
    }


# =========================
# 3. FINALIZAR STREAM
# =========================
@router.post("/streams/{stream_id}/end")
def end_stream(stream_id: str):
    supabase = get_global_supabase()

    response = supabase.table("streams") \
        .update({
            "status": "ended",
            "ended_at": datetime.utcnow().isoformat()
        }) \
        .eq("id", stream_id) \
        .execute()

    return {"status": "ended", "stream_id": stream_id}


# =========================
# 4. TOKEN VIEWER (LIVEKIT)
# =========================
@router.get("/streams/{stream_id}/viewer-token")
def get_viewer_token(stream_id: str):

    supabase = get_global_supabase()

    stream = supabase.table("streams") \
        .select("*") \
        .eq("id", stream_id) \
        .single() \
        .execute()

    if not stream.data:
        raise HTTPException(status_code=404, detail="Stream não encontrada")

    if stream.data["status"] != "live":
        raise HTTPException(status_code=400, detail="Stream não está ativa")

    identity = f"viewer_{uuid.uuid4().hex[:6]}"

    token = create_livekit_token(
        identity=identity,
        room=stream_id
    )

    return {
        "server_url": settings.LIVEKIT_URL,
        "token": token,
        "room": stream_id,
        "identity": identity
    }


# =========================
# 5. TOKEN HOST (LIVEKIT)
# =========================
@router.get("/streams/{stream_id}/host-token")
def get_host_token(stream_id: str):

    identity = f"host_{uuid.uuid4().hex[:6]}"

    token = create_livekit_token(
        identity=identity,
        room=stream_id
    )

    return {
        "server_url": settings.LIVEKIT_URL,
        "token": token,
        "room": stream_id,
        "identity": identity
    }

# ==================== LIVE CHAT SYSTEM ====================
@router.post("/{stream_id}/message")
async def post_message(stream_id: str, message: MessageCreate):
    """POST chat message com rate limit"""
    try:
        msg = send_message(message)
        print(f"💬 Message {msg.id[:8]} in {stream_id}")
        return msg
    except ValueError as e:
        raise HTTPException(status_code=429, detail=str(e))

@router.get("/{stream_id}/messages")
async def list_messages(stream_id: str, limit: int = Query(50, le=100), offset: int = 0):
    """GET mensagens paginadas stream"""
    messages = get_messages(stream_id, limit, offset)
    return {"messages": messages, "limit": limit, "offset": offset}
