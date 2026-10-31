from fastapi import APIRouter, HTTPException
from datetime import datetime
import logging
from app.db.supabase_client import get_global_supabase

router = APIRouter()

@router.get("/test-db")
async def test_db_read():
    try:
        supabase_client = get_global_supabase()
        response = supabase_client.table("users").select("*").limit(1).execute()
        data = response.data
        return {
            "status": "success",
            "message": "Leitura no banco users OK",
            "data": data
        }
    except Exception as e:
        logging.error(f"Supabase read error: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Erro na leitura: {str(e)}")

@router.get("/test-insert")
async def test_db_insert():
    try:
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        test_user = {
            "username": "teste_api",
            "email": f"teste_api_{timestamp}@email.com",
            "password": "123456"
        }
        supabase_client = get_global_supabase()
        response = supabase_client.table("users").insert(test_user).execute()
        data = response.data
        return {
            "status": "success",
            "message": "Inserção no banco users OK",
            "data": data,
            "inserted_user": test_user
        }
    except Exception as e:
        logging.error(f"Supabase insert error: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Erro na inserção: {str(e)}")

