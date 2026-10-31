from supabase import create_client, Client, ClientOptions
from app.config import settings
from typing import Optional

def get_supabase_client(token: Optional[str] = None) -> Client:
    """
    Token-aware Supabase client for RLS.
    Uses service_role_key internally, but passes user token for auth.uid()
    """
    headers = {}
    if token:
        headers['Authorization'] = f'Bearer {token}'
    
    options = ClientOptions(headers=headers)
    return create_client(settings.SUPABASE_URL, settings.SUPABASE_KEY, options=options)

# Global fallback (lazy init, no crash on startup)
supabase_global = None

def get_global_supabase() -> Optional[Client]:
    global supabase_global
    if supabase_global is None:
        try:
            key = settings.SUPABASE_SERVICE_ROLE_KEY or settings.SUPABASE_KEY
            supabase_global = create_client(settings.SUPABASE_URL, key)
            print("Global Supabase client created OK")
        except Exception as e:
            print(f"Global Supabase client FAILED: {str(e)[:100]} - Check .env")
            supabase_global = None
    return supabase_global
