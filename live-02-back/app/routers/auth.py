from fastapi import APIRouter, Depends, HTTPException, status
from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import OAuth2PasswordRequestForm
from app.security import verify_password, create_access_token, verify_supabase_token
from app.schemas import SupabaseLogin
from app.deps import get_supabase_token, get_current_user
from app.config import settings

router = APIRouter()

# Legacy custom JWT login (maintain compatibility)
@router.post("/login")
async def login(form_data: OAuth2PasswordRequestForm = Depends()):
    demo_username = form_data.username
    demo_password = form_data.password
    demo_hashed_password = "$2b$12$EixZaYVK1fsbw1ZfbpDvquZ8/RBL5kiUnM6Kl3gJ.DQeLshKcwHQ6"
    if not verify_password(demo_password, demo_hashed_password):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect username or password"
        )
    access_token = create_access_token(data={"sub": demo_username})
    return {"access_token": access_token, "token_type": "bearer"}

# New: Validate Supabase token and return user info
@router.post("/supabase-login", response_model=dict)
async def supabase_login(supabase_data: SupabaseLogin):
    """Flutter sends Supabase access_token → validate + return user_id"""
    token = supabase_data.access_token
    
    payload = verify_supabase_token(token)
    if not payload:
        raise HTTPException(
            status_code=401,
            detail="Invalid Supabase token"
        )
    
    return {
        "access_token": token,  # Return same token
        "token_type": "bearer",
        "user_id": payload["user_id"],
        "email": payload.get("email"),
        "username": payload["username"]
    }

@router.get("/me")
async def read_users_me(
    current_user: dict = Depends(get_current_user),
    supabase_token: str = Depends(get_supabase_token)
):
    return {
        "custom_user": current_user,
        "supabase_token_valid": bool(supabase_token)
    }
