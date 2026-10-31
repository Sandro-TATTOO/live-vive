from fastapi import APIRouter
from pydantic import BaseModel
from typing import List

router = APIRouter()

class CommentCreate(BaseModel):
    text: str
    stream_id: int
    user_id: int

class Comment(BaseModel):
    id: int
    text: str
    stream_id: int
    user_id: int

@router.post("/", response_model=Comment)
async def create_comment(comment: CommentCreate):
    return Comment(id=1, **comment.dict())

@router.get("/{stream_id}", response_model=List[Comment])
async def get_comments(stream_id: int):
    return [{"id": 1, "text": "Demo comment", "stream_id": stream_id, "user_id": 1}]

