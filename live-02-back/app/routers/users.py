from fastapi import APIRouter, Depends
from pydantic import BaseModel
from app.security import hash_password
from app.schemas import UserCreate, User

router = APIRouter()

@router.post("/create", response_model=User)
async def create_user(user: UserCreate):
    # Demo: hash password before "saving"
    hashed_password = hash_password(user.password)
    # In real app, save to DB: username, email, hashed_password
    return User(username=user.username, email=user.email)

@router.get("/{username}")
async def get_user(username: str):
    return {"username": username, "email": f"{username}@example.com"}


