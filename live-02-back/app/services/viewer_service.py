from app.db.supabase_client import get_global_supabase
from typing import Optional
from pydantic import BaseModel
import uuid
from datetime import datetime


class ViewerJoin(BaseModel):
    stream_id: str
    user_id: str


class ViewerStats(BaseModel):
    viewer_count: int


def join_stream(stream_id: str, user_id: str) -> ViewerStats:
    """Viewer entra no stream (idempotente)."""
    supabase = get_global_supabase()
    if not supabase:
        raise ValueError("Supabase not configured")

    # Check if already joined (idempotence)
    existing = supabase.table('stream_viewers') \
        .select('id') \
        .eq('stream_id', stream_id) \
        .eq('user_id', user_id) \
        .execute()

    if existing.data:
        count = supabase.rpc('get_viewer_count', {'stream_id': stream_id}).execute()
        val = count.data[0]['viewer_count'] if count.data else 0
        return ViewerStats(viewer_count=max(0, val))

    # Insert new viewer
    supabase.table('stream_viewers').insert({
        'id': str(uuid.uuid4()),
        'stream_id': stream_id,
        'user_id': user_id,
        'joined_at': datetime.utcnow().isoformat(),
    }).execute()

    # Increment count via RPC
    supabase.rpc('increment_viewers', {'stream_id': stream_id}).execute()

    count = supabase.rpc('get_viewer_count', {'stream_id': stream_id}).execute()
    val = count.data[0]['viewer_count'] if count.data else 0
    return ViewerStats(viewer_count=max(0, val))


def leave_stream(stream_id: str, user_id: str) -> ViewerStats:
    """Viewer sai do stream."""
    supabase = get_global_supabase()
    if not supabase:
        raise ValueError("Supabase not configured")

    # Remove viewer
    supabase.table('stream_viewers') \
        .delete() \
        .eq('stream_id', stream_id) \
        .eq('user_id', user_id) \
        .execute()

    # Decrement via RPC (safe, >=0)
    supabase.rpc('decrement_viewers', {'stream_id': stream_id}).execute()

    count = supabase.rpc('get_viewer_count', {'stream_id': stream_id}).execute()
    val = count.data[0]['viewer_count'] if count.data else 0
    return ViewerStats(viewer_count=max(0, val))


def get_viewer_count(stream_id: str) -> int:
    """Count atual viewers."""
    supabase = get_global_supabase()
    if not supabase:
        return 0

    count = supabase.rpc('get_viewer_count', {'stream_id': stream_id}).execute()
    if count.data:
        return max(0, count.data[0]['viewer_count'])
    return 0

