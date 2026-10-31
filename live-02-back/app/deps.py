from fastapi import Depends, HTTPException, status, Header
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from app.security import verify_supabase_token, verify_custom_token

security = HTTPBearer()

async def get_current_user(credentials: HTTPAuthorizationCredentials = Depends(security)):
    """Legacy custom token support"""
    token = credentials.credentials
    payload = verify_custom_token(token)
    if payload:
        username = payload.get("sub")
        if username:
            return {"username": username, "type": "custom"}
    raise HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Invalid custom token",
        headers={"WWW-Authenticate": "Bearer"},
    )

async def get_supabase_token(authorization: str = Header(None)) -> str:
    """Extract Supabase token from Authorization header"""
    if not authorization or not authorization.startswith('Bearer '):
        raise HTTPException(status_code=401, detail="Supabase token required")
    token = authorization.replace('Bearer ', '')
    
    # Validate token
    if not verify_supabase_token(token):
        raise HTTPException(status_code=401, detail="Invalid Supabase token")
    
    return token

async def get_supabase_client(authorization: str = Header(None)):
    """Dependency: Supabase client with user token for RLS"""
    from app.db.supabase_client import get_supabase_client
    token = await get_supabase_token(authorization)
    return get_supabase_client(token)
