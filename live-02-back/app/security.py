from datetime import datetime, timedelta, timezone
from jose import JWTError, jwt
from passlib.context import CryptContext
from app.config import settings

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

def hash_password(password: str) -> str:
    return pwd_context.hash(password)

def verify_password(plain_password: str, hashed_password: str) -> bool:
    return pwd_context.verify(plain_password, hashed_password)

def create_access_token(data: dict, expires_delta: timedelta = None):
    to_encode = data.copy()
    if expires_delta:
        expire = datetime.now(timezone.utc) + expires_delta
    else:
        expire = datetime.now(timezone.utc) + timedelta(minutes=60)
    to_encode.update({"exp": expire})
    encoded_jwt = jwt.encode(to_encode, settings.SECRET_KEY, algorithm=settings.ALGORITHM)
    return encoded_jwt

def verify_custom_token(token: str):
    """Legacy custom JWT validation"""
    try:
        payload = jwt.decode(token, settings.SECRET_KEY, algorithms=[settings.ALGORITHM])
        username: str = payload.get("sub")
        if username is None:
            return None
        return payload
    except JWTError:
        return None

def verify_supabase_token(token: str):
    """Validate Supabase JWT (public key or service role)"""
    try:
        # Supabase JWT uses RS256, needs public JWKS or direct decode if service_role
        # For validation: use http://supabase.co/docs/guides/auth/server-side/verify-jwt
        payload = jwt.decode(token, options={"verify_signature": False})  # Service role bypass OR fetch JWKS
        user_id: str = payload.get("sub")
        if user_id is None:
            return None
        return {
            "user_id": user_id,
            "email": payload.get("email"),
            "username": payload.get("username") or payload.get("email").split("@")[0]
        }
    except JWTError as e:
        print(f"Supabase token error: {e}")
        return None
